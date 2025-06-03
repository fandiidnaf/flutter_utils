from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from firebase_admin import messaging
from src.fcm import FCMService
from src.models import *


fcm: FCMService = FCMService('service-account-file.json')

# run web api with command -> fastapi dev --host 0.0.0.0 main.py
app: FastAPI = FastAPI(
            title="FCM FastAPI Server",
            description="API untuk mengirim notifikasi FCM menggunakan FastAPI dan Firebase Admin SDK.",
            version="1.0.0",
        )

app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],  # Ganti dengan asal spesifik Anda (misal: "http://localhost:3000") untuk produksi
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

device_tokens: List[str] = [] 


@app.get("/")
async def root():
    return {"message": "Selamat datang di FCM FastAPI Server!"}

@app.post("/register-token", summary="Mendaftarkan token perangkat")
async def register_token_device(data: RegisterToken):
    """
    Endpoint untuk mendaftarkan token pendaftaran FCM perangkat.
    Token ini akan disimpan secara lokal di server (untuk tujuan demo).
    Dalam aplikasi nyata, Anda mungkin akan menyimpannya di database.
    """
    if data.token not in device_tokens:
        device_tokens.append(data.token)
        print(f"Token perangkat baru terdaftar: {data.token}")
    else:
        print(f"Token {data.token} sudah terdaftar.")
    
    return {
        "message": "Token berhasil didaftarkan.", 
        "registered_tokens_count": len(device_tokens),
        "last_registered_token": data.token
    }

@app.get("/registered-tokens", summary="Melihat token perangkat yang terdaftar")
async def get_registered_tokens():
    """
    Endpoint untuk melihat daftar token perangkat yang saat ini terdaftar
    di server (disimpan dalam memori).
    """
    return {
        "message": "Daftar token perangkat yang terdaftar:",
        "tokens": device_tokens
    }

@app.post("/send-notification-to-device", summary="Kirim notifikasi ke perangkat spesifik")
async def send_notification_to_device(payload: SendToDevicePayload):
    """
    Mengirim notifikasi FCM ke satu perangkat spesifik menggunakan token pendaftarannya.
    """
    print(f"Mencoba mengirim notifikasi ke token: {payload.token}")
    
    # Buat objek messaging.Notification jika Anda ingin notifikasi standar
    notification_obj = messaging.Notification(
        title=payload.title,
        body=payload.body,
    ) if payload.title or payload.body else None # Hanya buat jika ada judul atau isi

    # Menggunakan payload.data sebagai data kustom
    response = fcm.send_message_to_spesific_device(
        token=payload.token,
        data={"title": payload.title, "body": payload.body, **payload.data}, # Gunakan data kustom dari payload
        # data={"title": payload.title, "body": payload.body, "payload": payload.data}, # Gunakan data kustom dari payload
        android=messaging.AndroidConfig(priority="high"), # Contoh konfigurasi Android
        apns=None,
        webpush=None
    )
    
    if response:
        return {"message": "Notifikasi berhasil dikirim.", "response_id": response}
    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Gagal mengirim notifikasi.")

@app.post("/send-notification-to-multiple-devices", summary="Kirim notifikasi ke banyak perangkat")
async def send_notification_to_multiple_devices(payload: SendToMultipleDevicesPayload):
    """
    Mengirim notifikasi FCM ke banyak perangkat menggunakan daftar token pendaftarannya.
    """
    print(f"Mencoba mengirim notifikasi ke {len(payload.tokens)} perangkat.")

    notification_obj = messaging.Notification(
        title=payload.title,
        body=payload.body,
    ) if payload.title or payload.body else None

    response = fcm.send_message_to_multiple_device(
        tokens=payload.tokens,
        data={"title": payload.title, "body": payload.body, **payload.data},
        android=messaging.AndroidConfig(priority="high"),
        apns=None,
        webpush=None
    )

    if response:
        return {
            "message": f"{response.success_count} notifikasi berhasil dikirifcm.",
            "success_count": response.success_count,
            "failure_count": response.failure_count,
            "responses": [{"token": payload.tokens[i], "success": r.success, "error": str(r.exception)} for i, r in enumerate(response.responses)]
        }
    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Gagal mengirim notifikasi.")

@app.post("/send-notification-to-topic", summary="Kirim notifikasi ke topik spesifik")
async def send_notification_to_topic(payload: SendToTopicPayload):
    """
    Mengirim notifikasi FCM ke semua perangkat yang berlangganan topik tertentu.
    """
    print(f"Mencoba mengirim notifikasi ke topik: {payload.topic}")

    notification_obj = messaging.Notification(
        title=payload.title,
        body=payload.body,
    ) if payload.title or payload.body else None

    response = fcm.send_message_to_specific_topic(
        topic=payload.topic,
        data={"title": payload.title, "body": payload.body, **payload.data},
        android=messaging.AndroidConfig(priority="high"),
        apns=None,
        webpush=None
    )

    if response:
        return {"message": "Notifikasi topik berhasil dikirifcm.", "response_id": response}
    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Gagal mengirim notifikasi ke topik.")

@app.post("/send-notification-by-condition", summary="Kirim notifikasi berdasarkan kondisi topik")
async def send_notification_by_condition(payload: SendToConditionPayload):
    """
    Mengirim notifikasi FCM ke perangkat berdasarkan kondisi topik (misal: 'TopicA' in topics && 'TopicB' in topics).
    """
    print(f"Mencoba mengirim notifikasi dengan kondisi: {payload.condition}")

    notification_obj = messaging.Notification(
        title=payload.title,
        body=payload.body,
    ) if payload.title or payload.body else None

    response = fcm.send_message_to_multiple_topic(
        condition=payload.condition,
        data={"title": payload.title, "body": payload.body, **payload.data},
        android=messaging.AndroidConfig(priority="high"),
        apns=None,
        webpush=None
    )

    if response:
        return {"message": "Notifikasi kondisi berhasil dikirifcm.", "response_id": response}
    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Gagal mengirim notifikasi berdasarkan kondisi.")

@app.post("/subscribe-to-topic", summary="Berlangganan token ke topik")
async def subscribe_to_topic(payload: TopicSubscriptionPayload):
    """
    Mendaftarkan satu atau lebih token perangkat ke topik FCfcm.
    """
    print(f"Mencoba subscribe {len(payload.tokens)} token ke topik: {payload.topic}")
    response = fcm.subscribe_topic_to_client(payload.tokens, payload.topic)
    if response:
        return {
            "message": f"{response.success_count} token berhasil berlangganan topik '{payload.topic}'.",
            "success_count": response.success_count,
            "failure_count": response.failure_count,
            "errors": [{"token": payload.tokens[i], "error": str(r.exception)} for i, r in enumerate(response.responses) if not r.success]
        }
    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Gagal berlangganan token ke topik.")

@app.post("/unsubscribe-from-topic", summary="Berhenti berlangganan token dari topik")
async def unsubscribe_from_topic(payload: TopicSubscriptionPayload):
    """
    Membatalkan langganan satu atau lebih token perangkat dari topik FCfcm.
    """
    print(f"Mencoba unsubscribe {len(payload.tokens)} token dari topik: {payload.topic}")
    response = fcm.unsubscribe_topic_from_client(payload.tokens, payload.topic)
    if response:
        return {
            "message": f"{response.success_count} token berhasil berhenti berlangganan dari topik '{payload.topic}'.",
            "success_count": response.success_count,
            "failure_count": response.failure_count,
            "errors": [{"token": payload.tokens[i], "error": str(r.exception)} for i, r in enumerate(response.responses) if not r.success]
        }
    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Gagal berhenti berlangganan token dari topik.")

