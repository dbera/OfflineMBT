import logging
import socket
import threading
import json
from typing import Optional, Dict

logger = logging.getLogger(__name__)

# Socket receive timeout in seconds
SOCKET_TIMEOUT = 30.0

class LSPProxy:
    """Proxy that forwards WebSocket messages to LSP subprocess over socket with proper LSP framing."""
    
    def __init__(self, lsp_port: int) -> None:
        self.lsp_port: int = lsp_port
        self.lsp_socket: Optional[socket.socket] = None
        self.connected: bool = False
        self.lock: threading.Lock = threading.Lock()
    
    def connect(self) -> bool:
        """Connect to the LSP subprocess on the specified port."""
        try:
            self.lsp_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.lsp_socket.settimeout(SOCKET_TIMEOUT)
            self.lsp_socket.connect(('127.0.0.1', self.lsp_port))
            self.connected = True
            logger.info(f"Connected to LSP subprocess on port {self.lsp_port}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to LSP subprocess: {e}")
            self.connected = False
            return False
    
    def disconnect(self) -> None:
        """Disconnect from the LSP subprocess."""
        try:
            self.connected = False
            if self.lsp_socket:
                self.lsp_socket.close()
            logger.info("Disconnected from LSP subprocess")
        except Exception as e:
            logger.error(f"Error disconnecting: {e}")
    
    def send_message(self, message: str) -> bool:
        """Send a message to LSP subprocess with proper LSP framing (Content-Length header)."""
        if not self.connected:
            logger.error("Not connected to LSP subprocess")
            return False
        
        try:
            with self.lock:
                # Validate JSON
                json.loads(message)
                
                # Create LSP message with Content-Length header
                content_bytes = message.encode('utf-8')
                content_length = len(content_bytes)
                header = f"Content-Length: {content_length}\r\n\r\n"
                
                # Send to LSP subprocess
                self.lsp_socket.sendall(header.encode('utf-8'))
                self.lsp_socket.sendall(content_bytes)
                
                logger.debug(f"Sent message to LSP subprocess: {len(content_bytes)} bytes")
                return True
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON message: {e}")
            return False
        except socket.timeout:
            logger.error("Socket timeout while sending message")
            self.connected = False
            return False
        except Exception as e:
            logger.error(f"Error sending message: {e}")
            self.connected = False
            return False
    
    def receive_message(self) -> Optional[str]:
        """Receive a message from LSP subprocess, parsing LSP headers."""
        if not self.connected:
            return None
        
        try:
            # Read headers line by line
            headers: Dict[str, str] = {}
            while True:
                line = self._read_line()
                if line is None:
                    logger.warning("Connection closed while reading headers")
                    self.connected = False
                    return None
                
                if not line:  # Empty line marks end of headers
                    break
                
                if ':' in line:
                    key, value = line.split(':', 1)
                    headers[key.strip()] = value.strip()
            
            if 'Content-Length' not in headers:
                logger.error("No Content-Length header in LSP response")
                return None
            
            # Read content
            content_length: int = int(headers['Content-Length'])
            content: bytes = b''
            while len(content) < content_length:
                chunk = self.lsp_socket.recv(content_length - len(content))
                if not chunk:
                    logger.warning("Connection closed while reading content")
                    self.connected = False
                    return None
                content += chunk
            
            message = content.decode('utf-8')
            logger.debug(f"Received message from LSP subprocess: {len(content)} bytes")
            return message
        except socket.timeout:
            # Timeout is normal - return None to continue waiting
            return None
        except Exception as e:
            logger.error(f"Error receiving message: {e}")
            self.connected = False
            return None
    
    def _read_line(self) -> Optional[str]:
        """Read a line from socket until CRLF."""
        line: bytes = b''
        while True:
            try:
                char: bytes = self.lsp_socket.recv(1)
                if not char:
                    return None
                line += char
                if line.endswith(b'\r\n'):
                    return line[:-2].decode('utf-8')
            except (socket.timeout, socket.error) as e:
                logger.error(f"Socket error reading line: {e}")
                raise
            except Exception as e:
                logger.error(f"Error reading line: {e}")
                return None



