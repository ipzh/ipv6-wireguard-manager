"""Utility helpers for working with MySQL database URLs and connection options.

These helpers ensure that MySQL connection URLs always include the UTF-8MB4
character set and that credentials can be used safely with drivers such as
PyMySQL that internally encode passwords using latin-1.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple
from urllib.parse import parse_qsl, quote, urlencode, urlparse, urlunparse, unquote

MYSQL_CHARSET = "utf8mb4"


def _is_mysql_scheme(scheme: str) -> bool:
    """Return True when the URL scheme represents a MySQL connection."""
    if not scheme:
        return False
    scheme_lower = scheme.lower()
    return scheme_lower.startswith("mysql")


def _encode_mysql_password(password: str) -> Tuple[str, str]:
    """Return the password in a form acceptable for MySQL drivers.

    PyMySQL (and therefore aiomysql) expects password strings to be encodable via
    latin-1. When the original password contains characters outside of the
    latin-1 range (for example emoji), attempting to connect raises a
    ``UnicodeEncodeError``. To preserve the original password bytes we encode the
    password using UTF-8 and then decode it using latin-1 so that each byte value
    is stored in a single latin-1 code point.

    The return value contains the transformed password along with the encoding
    that should be used when URL-encoding it again.
    """

    if not password:
        return "", "utf-8"

    try:
        password.encode("latin1")
        return password, "utf-8"
    except UnicodeEncodeError:
        transformed = password.encode("utf-8").decode("latin1")
        return transformed, "latin1"


def _build_netloc(
    username: str,
    encoded_password: Optional[str],
    password_present: bool,
    hostname: Optional[str],
    port: Optional[int],
) -> str:
    """Reconstruct the network location component for the URL."""

    pieces: List[str] = []

    if username or password_present:
        pieces.append(username)
        if password_present:
            pieces.append(":" + (encoded_password or ""))
        pieces.append("@")

    if hostname:
        if ":" in hostname and not hostname.startswith("["):
            pieces.append(f"[{hostname}]")
        else:
            pieces.append(hostname)

    if port is not None:
        pieces.append(f":{port}")

    return "".join(pieces)


def _ensure_charset_query(query_pairs: List[Tuple[str, str]]) -> List[Tuple[str, str]]:
    """Ensure the charset query parameter is present (case-insensitive check)."""

    if any(key.lower() == "charset" for key, _ in query_pairs):
        return query_pairs

    query_pairs.append(("charset", MYSQL_CHARSET))
    return query_pairs


def ensure_mysql_url_compat(database_url: str) -> str:
    """Return a MySQL URL that is safe for drivers expecting latin-1 passwords.

    - Guarantees that the ``charset`` query parameter is present and set to
      UTF-8MB4.
    - Re-encodes passwords containing characters outside latin-1 so that they
      can be consumed by PyMySQL/aiomysql without raising ``UnicodeEncodeError``.
    """

    if not database_url:
        return database_url

    parsed = urlparse(database_url)
    if not _is_mysql_scheme(parsed.scheme):
        return database_url

    username = quote(unquote(parsed.username or ""), safe="")
    password_present = parsed.password is not None
    raw_password = unquote(parsed.password) if parsed.password is not None else ""
    password_for_driver, password_encoding = _encode_mysql_password(raw_password)
    encoded_password = (
        quote(password_for_driver, safe="", encoding=password_encoding)
        if password_present
        else None
    )

    hostname = parsed.hostname or ""
    netloc = _build_netloc(username, encoded_password, password_present, hostname, parsed.port)

    query_pairs = list(parse_qsl(parsed.query, keep_blank_values=True))
    query_pairs = _ensure_charset_query(query_pairs)
    query = urlencode(query_pairs, doseq=True)

    rebuilt = urlunparse(
        (
            parsed.scheme,
            netloc,
            parsed.path or "",
            parsed.params,
            query,
            parsed.fragment,
        )
    )
    return rebuilt


def ensure_mysql_connect_args(connect_args: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Merge default MySQL connection arguments with the provided mapping.

    Note: This function does not inspect the DATABASE_URL. If you need to
    derive options like unix_socket from the URL, use
    :func:`get_mysql_connect_args_from_url`.
    """

    merged: Dict[str, Any] = dict(connect_args or {})
    merged.setdefault("charset", MYSQL_CHARSET)
    merged.setdefault("use_unicode", True)
    return merged


def get_mysql_connect_args_from_url(database_url: str, extra: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Return driver connect_args derived from a MySQL SQLAlchemy URL string.

    - Preserves existing connect_args from ``extra``
    - Ensures ``charset=utf8mb4`` and ``use_unicode=True``
    - If the URL query contains ``unix_socket=...``, propagates it to connect_args
    """

    args = dict(extra or {})
    args.setdefault("charset", MYSQL_CHARSET)
    args.setdefault("use_unicode", True)

    if not database_url:
        return args

    parsed = urlparse(database_url if isinstance(database_url, str) else str(database_url))
    if not _is_mysql_scheme(parsed.scheme):
        return args

    query_pairs = dict(parse_qsl(parsed.query, keep_blank_values=True))
    # sqlalchemy+pymysql supports passing unix_socket in connect_args
    unix_socket = query_pairs.get("unix_socket") or query_pairs.get("unix-socket")
    if unix_socket:
        args.setdefault("unix_socket", unix_socket)

    return args


def get_mysql_driver_password(password: str) -> str:
    """Return a password representation safe for MySQL python drivers."""

    return _encode_mysql_password(password)[0]


def prepare_sqlalchemy_mysql_url(database_url: str):
    """Return a SQLAlchemy URL with mysql-specific adjustments."""

    from sqlalchemy.engine.url import make_url

    url_obj = make_url(database_url)
    if not _is_mysql_scheme(url_obj.drivername):
        return url_obj

    query = dict(url_obj.query)
    if not any(key.lower() == "charset" for key in query):
        query["charset"] = MYSQL_CHARSET
        url_obj = url_obj.set(query=query)
    elif query.get("charset") is None:
        query["charset"] = MYSQL_CHARSET
        url_obj = url_obj.set(query=query)

    password = url_obj.password
    if password:
        driver_password, _ = _encode_mysql_password(password)
        url_obj = url_obj.set(password=driver_password)

    return url_obj


__all__ = [
    "MYSQL_CHARSET",
    "ensure_mysql_connect_args",
    "get_mysql_connect_args_from_url",
    "ensure_mysql_url_compat",
    "get_mysql_driver_password",
    "prepare_sqlalchemy_mysql_url",
]
