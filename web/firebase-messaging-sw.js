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

function iconUrl() {
  return new URL('icons/Icon-192.png', self.registration.scope).href;
}

function buildNotificationPayload(payload) {
  const title = payload.notification?.title || payload.data?.title || 'New Notification';
  const body = payload.notification?.body || payload.data?.body || 'You have a new update.';
  const type = payload.data?.type;
  const subType = payload.data?.subType;
  const isNewOrder = type === 'NEW_ORDER' || subType === 'PENDING_ORDER';
  const orderId = payload.data?.orderId || payload.data?.order_id || 'new';

  return {
    title,
    body,
    isNewOrder,
    orderId,
    options: {
      body: body,
      icon: iconUrl(),
      badge: iconUrl(),
      data: payload.data || {},
      tag: isNewOrder ? 'order-' + orderId : 'shop-update',
      requireInteraction: isNewOrder,
      silent: false,
      renotify: true,
    },
  };
}

function notifyOpenClients(payload, title, body) {
  return self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
    clientList.forEach(function (client) {
      client.postMessage({
        type: 'NEW_ORDER_ALERT',
        orderId: payload.data?.orderId || payload.data?.order_id || null,
        title: title,
        body: body,
      });
    });
  });
}

function showPushNotification(payload) {
  const built = buildNotificationPayload(payload);
  const tasks = [self.registration.showNotification(built.title, built.options)];

  if (built.isNewOrder) {
    tasks.push(notifyOpenClients(payload, built.title, built.body));
  }

  return Promise.all(tasks);
}

messaging.onBackgroundMessage(function (payload) {
  console.log('[firebase-messaging-sw.js] onBackgroundMessage', payload);
  return showPushNotification(payload);
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
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
