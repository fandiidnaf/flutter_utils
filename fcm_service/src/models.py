from pydantic import BaseModel, Field
from typing import List, Dict, Optional

# --- Pydantic Models for Request Bodies ---

class RegisterToken(BaseModel):
    """Model untuk mendaftarkan token perangkat."""
    token: str = Field(..., description="Token pendaftaran FCM perangkat.")

class NotificationPayload(BaseModel):
    """Model dasar untuk payload notifikasi."""
    title: str = Field(..., description="Judul notifikasi.")
    body: str = Field(..., description="Isi notifikasi.")
    data: Optional[Dict[str, str]] = Field(default_factory=dict, description="Data kustom opsional untuk notifikasi.")

class SendToDevicePayload(NotificationPayload):
    """Model untuk mengirim notifikasi ke satu perangkat."""
    token: str = Field(..., description="Token pendaftaran FCM perangkat tujuan.")

class SendToMultipleDevicesPayload(NotificationPayload):
    """Model untuk mengirim notifikasi ke banyak perangkat."""
    tokens: List[str] = Field(..., min_items=1, description="Daftar token pendaftaran FCM perangkat tujuan.")

class SendToTopicPayload(NotificationPayload):
    """Model untuk mengirim notifikasi ke satu topik."""
    topic: str = Field(..., description="Nama topik FCM.")

class SendToConditionPayload(NotificationPayload):
    """Model untuk mengirim notifikasi berdasarkan kondisi topik."""
    condition: str = Field(..., description="Kondisi topik FCM (misal: 'TopicA' in topics && 'TopicB' in topics).")

class TopicSubscriptionPayload(BaseModel):
    """Model untuk subscribe atau unsubscribe token dari topik."""
    tokens: List[str] = Field(..., min_items=1, description="Daftar token pendaftaran FCM.")
    topic: str = Field(..., description="Nama topik FCM.")
