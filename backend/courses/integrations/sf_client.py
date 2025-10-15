from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Dict, Optional
import requests
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter

@dataclass
class SuccessFactorsClient:
    base_url: str
    token: str
    timeout_sec: float = 10.0

    def _session(self) -> requests.Session:
        s = requests.Session()
        retries = Retry(total=3, backoff_factor=0.5, status_forcelist=(429, 500, 502, 503, 504))
        s.mount("https://", HTTPAdapter(max_retries=retries))
        s.headers.update({
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/json",
        })
        return s

    def get_user(self, user_id: str) -> Dict[str, Any]:
        url = f"{self.base_url}/odata/v2/User('{user_id}')"
        with self._session() as s:
            resp = s.get(url, timeout=self.timeout_sec)
            resp.raise_for_status()
            data = resp.json()
            # Vereinfachte Extraktion
            return data.get("d", {})

    def ping(self) -> bool:
        try:
            with self._session() as s:
                resp = s.get(f"{self.base_url}/odata/v2", timeout=self.timeout_sec)
                resp.raise_for_status()
                return True
        except requests.RequestException:
            return False
