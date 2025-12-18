#
# Copyright (c) 2024, 2025 TNO-ESI
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available
# under the terms of the MIT License which is available at
# https://opensource.org/licenses/MIT
#
# SPDX-License-Identifier: MIT
#

from __future__ import annotations

import io
import json
import os
from typing import Dict, Any, List, Tuple, Optional, Union
import requests
from requests.exceptions import RequestException, ConnectionError, Timeout


class CPNClientError(Exception):
    """Raised for non-2xx responses or parse errors."""
    def __init__(self, message: str, status_code: Optional[int] = None, payload: Optional[dict] = None):
        super().__init__(message)
        self.status_code = status_code
        self.payload = payload or {}


class CPNClient:
    """
    Python client for the Flask REST API in CPNServer.py.

    Features:
      - Upload BPMN (filename sent without extension) and obtain UUID
      - Load scenarios (JSON file field)
      - Query markings and enabled transitions
      - Fire transitions by choice id
      - Save/restore/goto markings
      - Generate tests ZIP from BPMN (saved next to BPMN or to a custom path)
    """
    def __init__(self, base_url: str, timeout: int = 60):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.session = requests.Session()

    # ------------------------------
    # Helpers
    # ------------------------------
    def _check(self, resp: requests.Response) -> Union[dict, bytes]:
        """Raise a detailed error for non-2xx; return JSON if present else raw bytes."""
        if 200 <= resp.status_code < 300:
            ctype = resp.headers.get("Content-Type", "")
            if "application/json" in ctype:
                try:
                    return resp.json()
                except Exception as e:
                    raise CPNClientError(f"Failed to parse JSON response: {e}", payload={"text": resp.text})
            else:
                return resp.content
        else:
            payload = {}
            try:
                payload = resp.json()
            except Exception:
                payload = {"text": resp.text}
            raise CPNClientError(f"HTTP {resp.status_code}: {payload}", status_code=resp.status_code, payload=payload)

    def _name_without_ext(self, path: str) -> str:
        return os.path.splitext(os.path.basename(path))[0]

    def _safe(self, fn, *args, **kwargs):
        """Wrap requests calls to provide a friendly error when server is unreachable."""
        try:
            return fn(*args, **kwargs)
        except (ConnectionError, Timeout) as e:
            raise CPNClientError(f"Cannot contact CPN server at {self.base_url}: {e}")
        except RequestException as e:
            raise CPNClientError(f"CPN server request failed: {e}")

    # ------------------------------
    # BPMN lifecycle
    # ------------------------------
    def upload_bpmn(self, bpmn_path: str) -> Dict[str, Any]:
        """
        POST /BPMNParser
        Upload a BPMN file and load the generated module.
        Sends the filename without its extension in the multipart payload.
        Returns a JSON object including the generated UUID.
        """
        url = f"{self.base_url}/BPMNParser"
        with open(bpmn_path, "rb") as f:
            files = {"bpmn-file": (self._name_without_ext(bpmn_path), f, "application/xml")}
            resp = self._safe(self.session.post, url, files=files, timeout=self.timeout)
        return self._check(resp)

    def unload_bpmn(self, uuid: str) -> Dict[str, Any]:
        url = f"{self.base_url}/BPMNParser/{uuid}"
        resp = self._safe(self.session.delete, url, timeout=self.timeout)
        return self._check(resp)

    def ping_module(self, uuid: str) -> Dict[str, Any]:
        url = f"{self.base_url}/CPNServer/{uuid}"
        resp = self._safe(self.session.get, url, timeout=self.timeout)
        return self._check(resp)

    # ------------------------------
    # Scenario
    # ------------------------------
    def load_scenario(self, uuid: str, scenario_json: Union[Dict[str, Any], List[Any]]) -> Dict[str, Any]:
        """
        POST /CPNServer/<uuid>/scenario/load
        Uploads the scenario JSON via a file field 'scenario-file'.
        """
        url = f"{self.base_url}/CPNServer/{uuid}/scenario/load"
        data = json.dumps(scenario_json).encode("utf-8")
        files = {"scenario-file": ("scenario.json", io.BytesIO(data), "application/json")}
        resp = self._safe(self.session.post, url, files=files, timeout=self.timeout)
        return self._check(resp)

    # ------------------------------
    # Markings
    # ------------------------------
    def get_markings(self, uuid: str) -> Dict[str, List[Tuple[Any, int]]]:
        url = f"{self.base_url}/CPNServer/{uuid}/markings"
        resp = self._safe(self.session.get, url, timeout=self.timeout)
        return self._check(resp)

    def save_marking(self, uuid: str) -> Dict[str, Any]:
        url = f"{self.base_url}/CPNServer/{uuid}/markings/save"
        resp = self._safe(self.session.post, url, timeout=self.timeout)
        return self._check(resp)

    def restore_marking(self, uuid: str) -> Dict[str, Any]:
        url = f"{self.base_url}/CPNServer/{uuid}/markings/restore"
        resp = self._safe(self.session.post, url, timeout=self.timeout)
        return self._check(resp)

    def goto_marking(self, uuid: str, index: int) -> Dict[str, Any]:
        url = f"{self.base_url}/CPNServer/{uuid}/markings/goto"
        resp = self._safe(self.session.post, url, json={"index": index}, timeout=self.timeout)
        return self._check(resp)

    # ------------------------------
    # Transitions
    # ------------------------------
    def get_enabled_transitions(self, uuid: str) -> Dict[str, Dict[str, Any]]:
        url = f"{self.base_url}/CPNServer/{uuid}/transitions/enabled"
        resp = self._safe(self.session.get, url, timeout=self.timeout)
        return self._check(resp)

    def fire_transition(self, uuid: str, choice_id: int) -> Dict[str, Any]:
        url = f"{self.base_url}/CPNServer/{uuid}/transition/fire"
        resp = self._safe(self.session.post, url, json={"choice": choice_id}, timeout=self.timeout)
        return self._check(resp)

    # ------------------------------
    # Test generation (ZIP)
    # ------------------------------
    def generate_tests(
        self,
        bpmn_path: str,
        num_tests: int = 1,
        depth_limit: int = 1000,
        save_to: Optional[str] = None
    ) -> str:
        """
        POST /TestGenerator
        Uploads BPMN (filename sent without extension) and receives a ZIP stream.
        Saves to `save_to` if provided, else next to BPMN as `<basename>.zip`.
        Returns the path to the saved ZIP.
        """
        url = f"{self.base_url}/TestGenerator"
        with open(bpmn_path, "rb") as f:
            files = {"bpmn-file": (self._name_without_ext(bpmn_path), f, "application/xml")}
            form = {"prj-params": json.dumps({"num-tests": num_tests, "depth-limit": depth_limit})}
            resp = self._safe(self.session.post, url, files=files, data=form, timeout=max(self.timeout, 120))
        content = self._check(resp)

        zip_path = save_to if save_to else os.path.splitext(bpmn_path)[0] + ".zip"
        with open(zip_path, "wb") as zf:
            zf.write(content)
        return zip_path
