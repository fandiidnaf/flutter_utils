import firebase_admin
from firebase_admin import credentials, messaging
from firebase_admin.exceptions import FirebaseError

class FCMService:
    def __init__(self, service_account_file_path: str) -> None:
        cred: credentials.Certificate = credentials.Certificate(service_account_file_path)
        self.app: firebase_admin.App = firebase_admin.initialize_app(cred)

    def send_message_to_spesific_device(
            self, 
            token: str, 
            data: dict[str, str] | None, 
            android: messaging.AndroidConfig | None, 
            apns: messaging.APNSConfig | None, 
            webpush: messaging.WebpushConfig | None,
        ) -> str:
        try:
            message: messaging.Message = messaging.Message(
                data=data,
                token=token,
                android=android,
                apns=apns,
                webpush=webpush,
            )

            # Send a message to the device corresponding to the provided
            # registration token.
            response: str = messaging.send(message)
            print('Successfully sent message:', response)
            return response
        except FirebaseError as e:
            print('Error sending message: ', e)
        except ValueError as e:
            print("input argument invalid: ", e)

    def send_message_to_multiple_device(
            self, 
            tokens: list[str], 
            data: dict[str, str] | None, 
            android: messaging.AndroidConfig | None, 
            apns: messaging.APNSConfig | None, 
            webpush: messaging.WebpushConfig | None,
        ) -> messaging.BatchResponse:
        try:
            # Create a list containing up to 500 registration tokens.
            message: messaging.MulticastMessage = messaging.MulticastMessage(
                data=data,
                tokens=tokens,
                android=android,
                apns=apns,
                webpush=webpush,
            )
            response: messaging.BatchResponse = messaging.send_each_for_multicast(message)
            # See the BatchResponse reference documentation
            # for the contents of response.
            print('{0} messages were sent successfully'.format(response.success_count))

            if response.failure_count > 0:
                responses = response.responses
                failed_tokens = []
                for idx, resp in enumerate(responses):
                    if not resp.success:
                        # The order of responses corresponds to the order of the registration tokens.
                        failed_tokens.append(tokens[idx])
                print('List of tokens that caused failures: {0}'.format(failed_tokens))
            
            return response
        except FirebaseError as e:
            print('Error sending message: ', e)
        except ValueError as e:
            print("input argument invalid: ", e)

    def send_message_to_specific_topic(
            self, 
            topic: str, 
            data: dict[str, str] | None, 
            android: messaging.AndroidConfig | None, 
            apns: messaging.APNSConfig | None, 
            webpush: messaging.WebpushConfig | None,
        ) -> str:
        try:
            # The topic name can be optionally prefixed with "/topics/".

            # See documentation on defining a message payload.
            message: messaging.Message = messaging.Message(
                data=data,
                topic=topic,
                android=android,
                apns=apns,
                webpush=webpush
            )

            # Send a message to the devices subscribed to the provided topic.
            response: str = messaging.send(message)
            # Response is a message ID string.
            print('Successfully sent message:', response)

            return response
        except FirebaseError as e:
            print('Error sending message: ', e)
        except ValueError as e:
            print("input argument invalid: ", e)

    def send_message_to_multiple_topic(
            self, 
            condition: str, 
            data: dict[str, str] | None, 
            android: messaging.AndroidConfig | None, 
            apns: messaging.APNSConfig | None, 
            webpush: messaging.WebpushConfig | None,
        ) -> str:
        '''
        parameyer condition, ex: "'TopicA' in topics && ('TopicB' in topics || 'TopicC' in topics)"
        
        note: 'in topics' is required
        '''
        try:
            # The topic name can be optionally prefixed with "/topics/".

            # See documentation on defining a message payload.
            message: messaging.Message = messaging.Message(
                data=data,
                condition=condition,
                android=android,
                apns=apns,
                webpush=webpush,
            )

            # Send a message to the devices subscribed to the provided topic.
            response: str = messaging.send(message)
            # Response is a message ID string.
            print('Successfully sent message:', response)

            return response
        except FirebaseError as e:
            print('Error sending message: ', e)
        except ValueError as e:
            print("input argument invalid: ", e)

    def subscribe_topic_to_client(self, tokens: list[str], topic: str) -> messaging.TopicManagementResponse:
        try:
            response: messaging.TopicManagementResponse = messaging.subscribe_to_topic(tokens, topic)
            print(response.success_count, 'tokens were subscribed successfully')
            return response
        except FirebaseError as e:
            print('Error sending message: ', e)
        except ValueError as e:
            print("input argument invalid: ", e)

    def unsubscribe_topic_from_client(self, tokens: list[str], topic: str) -> messaging.TopicManagementResponse:
        try:
            response: messaging.TopicManagementResponse = messaging.unsubscribe_from_topic(tokens, topic)
            print(response.success_count, 'tokens were subscribed successfully')
            return response
        except FirebaseError as e:
            print('Error sending message: ', e)
        except ValueError as e:
            print("input argument invalid: ", e)
