"""
BGP相关Schema
"""
from typing import Optional, List
from pydantic import BaseModel, Field


class BGPSessionBase(BaseModel):
    name: str
    neighbor: str
    remote_as: int
    hold_time: Optional[int] = None
    password: Optional[str] = None
    description: Optional[str] = None
    enabled: bool = True


class BGPSessionCreate(BGPSessionBase):
    pass


class BGPSessionUpdate(BaseModel):
    name: Optional[str] = None
    neighbor: Optional[str] = None
    remote_as: Optional[int] = None
    hold_time: Optional[int] = None
    password: Optional[str] = None
    description: Optional[str] = None
    enabled: Optional[bool] = None


class BGPSession(BGPSessionBase):
    id: int

    class Config:
        from_attributes = True


class BGPAnnouncementBase(BaseModel):
    prefix: str
    asn: Optional[int] = None
    next_hop: Optional[str] = None
    description: Optional[str] = None
    enabled: bool = True
    session_id: Optional[int] = Field(default=None)


class BGPAnnouncementCreate(BGPAnnouncementBase):
    pass


class BGPAnnouncementUpdate(BaseModel):
    prefix: Optional[str] = None
    asn: Optional[int] = None
    next_hop: Optional[str] = None
    description: Optional[str] = None
    enabled: Optional[bool] = None
    session_id: Optional[int] = None


class BGPAnnouncement(BGPAnnouncementBase):
    id: int

    class Config:
        from_attributes = True


class BGPAnnouncementList(BaseModel):
    announcements: List[BGPAnnouncement]