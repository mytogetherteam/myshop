importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyDvyZGjQsgZuZ5VT3wmqAI0edN04Ox_FxM",
  authDomain: "mytogether-daf3f.firebaseapp.com",
  projectId: "mytogether-daf3f",
  storageBucket: "mytogether-daf3f.firebasestorage.app",
  messagingSenderId: "972280179999",
  appId: "1:972280179999:web:2948e4ee866168ad69542a"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const title = payload.notification?.title || payload.data?.title || 'New Notification';
  const body = payload.notification?.body || payload.data?.body || 'You have a new update.';
  
  const type = payload.data?.type;
  const subType = payload.data?.subType;
  const isNewOrder = type === 'NEW_ORDER' || subType === 'PENDING_ORDER';

  // For orders, we can try to play a sound, but standard Web Notification 
  // API doesn't support custom sound file paths directly in all browsers.
  // We can use the 'silent' flag to false and let the system play its default notification sound.
  const notificationOptions = {
    body: body,
    icon: '/icons/Icon-192.png',
    data: payload.data,
    requireInteraction: isNewOrder // keep the notification open until the user interacts
  };

  return self.registration.showNotification(title, notificationOptions);
});

// Handle notification click to focus or open the app
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url.includes(self.registration.scope) && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
