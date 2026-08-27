import json
import traceback
from enum import Enum
from typing import List, Optional, Dict, Any, NoReturn
from dataclasses import dataclass, field
from pathlib import Path

class StatusException(Exception):
    def __init__(self, message: str):
        super().__init__(message)

class Severity(Enum):
    OK = 0
    INFO = 1
    WARNING = 2
    ERROR = 3
    CANCEL = 4

@dataclass 
class Location:
    startLine: int
    endLine: int
    offset: int
    length: int
    text: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            'startLine': self.startLine,
            'endLine': self.endLine,
            'offset': self.offset,
            'length': self.length,
            'text': self.text,
        }

@dataclass
class StatusReport:
    plugin: str
    severity: Severity
    message: str
    source: str = ""
    code: int = 0
    details: Optional[str] = None
    location: Optional[Location] = None
    children: List['StatusReport'] = field(default_factory=list)
    exception: Optional[Exception] = field(default=None, repr=False)

    def __post_init__(self):
        if self.exception is not None:
            if self.details is None:
                self.details = self._get_stack_trace_as_string(self.exception)
            self.exception = None  # Don't retain non-serializable object

        if self.children:
            child_severities = [child.severity for child in self.children if child is not None]
            if child_severities:
                max_child_severity = max(child_severities, key=lambda s: s.value)
                if max_child_severity.value > self.severity.value:
                    self.severity = max_child_severity

    @staticmethod
    def _get_stack_trace_as_string(exception: Optional[Exception]) -> Optional[str]:
        if exception is None:
            return None
        tb_lines = traceback.format_exception(type(exception), exception, exception.__traceback__)
        if len(tb_lines) > 15:
            tb_lines = tb_lines[:15] + [f"   ... {len(tb_lines) - 15} more" +"\n"]
        return "".join(tb_lines)

    def to_dict(self) -> Dict[str, Any]:
        return {
            'plugin': self.plugin,
            'severity': self.severity.name,
            'message': self.message,
            'source': self.source,
            'code': self.code,
            'details': self.details,
            'location': self.location.to_dict() if self.location else None,
            'children': [child.to_dict() for child in self.children if child is not None],
        }

class StatusReporting:
    def __init__(self, save_path: str):
        self.save_path = Path(save_path)
        self.reports: List[StatusReport] = []

    def _log(self, severity: Severity, message: str, source: str = "", code: int = 0,
             details: Optional[str] = None, exception: Optional[Exception] = None, location: Optional[Location] = None) -> StatusReport:
        report = StatusReport(
            plugin="",
            severity=severity,
            message=message,
            source=source,
            code=code,
            details=details,
            location=location,
            exception=exception
        )
        self.reports.append(report)
        return report

    def info(self, message: str, source: str = "", code: int = 0, details: Optional[str] = None, location: Optional[Location] = None) -> StatusReport:
        return self._log(Severity.INFO, message, source, code, details, None, location)

    def warning(self, message: str, source: str = "", code: int = 0, details: Optional[str] = None, location: Optional[Location] = None) -> StatusReport:
        return self._log(Severity.WARNING, message, source, code, details, None, location)

    def error(self, message: str, source: str = "", code: int = 0, 
              details: Optional[str] = None, location: Optional[Location] = None) -> StatusReport:
        return self._log(Severity.ERROR, message, source, code, details, None, location)

    def exception(self, message: str, exception: Exception, source: str = "", details: Optional[str] = None, code: int = 0, location: Optional[Location] = None) -> NoReturn:
        self._log(Severity.ERROR, message, source, code, details, exception, location)
        #on exception the process is stopped
        raise StatusException(message)

    def save(self) -> Severity:

        root_severity = Severity.OK
        if self.reports:
            root_severity = max((report.severity for report in self.reports), key=lambda s: s.value)

        root_report = StatusReport(
            plugin="",
            severity=root_severity,
            message=f"Python generation of printer",
            source="",
            code=0,
            details=None,
            location=None,
            children=self.reports,
            exception=None
        )

        data = root_report.to_dict()
        with open(self.save_path, 'w') as f:
            json.dump(data, f, indent=2)

        return root_severity

_status_reporting_instance: Optional[StatusReporting] = None

def initialize_reporting(save_path: str) -> StatusReporting:
    global _status_reporting_instance
    _status_reporting_instance = StatusReporting(save_path)
    return _status_reporting_instance

def get_reporting() -> StatusReporting:
    global _status_reporting_instance
    if _status_reporting_instance is None:
        raise RuntimeError("StatusReporting not initialized. Call initialize_reporting() first.")
    return _status_reporting_instance