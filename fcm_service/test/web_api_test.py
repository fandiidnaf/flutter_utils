from enum import Enum

class APIMethod(Enum):
    GET = 1
    POST = 2

class APIPaths(Enum):
    REGISTER_TOKEN = "register-token"
    REGISTERED_TOKENS = "registered-tokens"
    SEND_NOTIFICATION_TO_DEVICE = "send-notification-to-device"
    SEND_NOTIFICATION_TO_MULTIPLE_DEVICE = "send-notification-to-multiple-device"
    SEND_NOTIFICATION_TO_TOPIC = "send-notification-to-topic"
    SEND_NOTIFICATION_BY_CONDITION = "send-notification-by-condition"
    SUBSCRIBE_TO_TOPIC = "subscribe-to-topic"
    UNSUBSCRIBE_FROM_TOPIC = "unsubscribe-to-topic"

def test_api(method: APIMethod, path: APIPaths, data: dict[str, str]) -> None:
    import requests

    base_url = "http://127.0.0.1:8000"

    url = f"{base_url}/{path.value}"
    response: requests.Response = None

    match method:
        case APIMethod.GET:
            response = requests.get(url)
        case APIMethod.POST:
            response = requests.post(url, json=data)

    print(response.json())

def main() -> None:
    method: APIMethod = APIMethod.POST
    path: APIPaths = APIPaths.SEND_NOTIFICATION_TO_DEVICE
    data: dict[str, str] = {
        "token": "dS4peFyuR5-bvGWSECWzN2:APA91bGFNEeNUf0Bx4TUQLQMoope-cXnTNmBfbtSMgiQrrcsOKnyStHaoYqpA8B7Fu-jl70JrJeh3VAN-5J3lvfdLcOPBn3gTgj4W-n8E2p2kAO2nPJwBX8",

        "title": "First nih bang",
        "body": "data",
        "data": {
            "route": "/home"
        },
    }

    test_api(
        method=method,
        path=path,
        data=data,
    )

if __name__ == "__main__":
    main()
