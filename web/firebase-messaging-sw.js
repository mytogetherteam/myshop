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
const ALERT_CACHE = 'myshop-order-alerts-v1';

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

function assetUrl(path) {
  return self.location.origin + '/' + path.replace(/^\//, '');
}

function iconUrl() {
  return assetUrl('icons/Icon-192.png');
}

function alertSoundUrl() {
  return assetUrl('assets/assets/alert/alert.mp3');
}

function normalizePayload(payload) {
  const data = payload.data || {};
  const type = data.type || payload.type;
  const subType = data.subType || data.sub_type || payload.subType;
  const isNewOrder = type === 'NEW_ORDER' || subType === 'PENDING_ORDER';
  const orderId = data.orderId || data.order_id || payload.orderId || payload.order_id || 'new';
  const title =
    payload.notification?.title ||
    data.title ||
    (isNewOrder ? 'New Order' : 'New Notification');
  const body =
    payload.notification?.body ||
    data.body ||
    (isNewOrder ? 'You have a new order waiting.' : 'You have a new update.');

  return {
    title: title,
    body: body,
    isNewOrder: isNewOrder,
    orderId: orderId,
    data: Object.assign({}, data, {
      type: type || data.type,
      subType: subType || data.subType,
      orderId: orderId,
      title: title,
      body: body,
    }),
  };
}

function storePendingOrderAlert(orderId) {
  var payload = JSON.stringify({
    orderId: orderId || 'new',
    at: Date.now(),
  });

  return caches.open(ALERT_CACHE).then(function (cache) {
    return cache.put(
      new Request('pending-order-alert'),
      new Response(payload, { headers: { 'Content-Type': 'application/json' } })
    );
  }).catch(function (err) {
    console.log('[firebase-messaging-sw.js] store pending alert failed', err);
  });
}

function buildNotificationPayload(payload) {
  const normalized = normalizePayload(payload);

  return {
    title: normalized.title,
    body: normalized.body,
    isNewOrder: normalized.isNewOrder,
    orderId: normalized.orderId,
    options: {
      body: normalized.body,
      icon: iconUrl(),
      badge: iconUrl(),
      data: normalized.data,
      tag: normalized.isNewOrder ? 'order-' + normalized.orderId : 'shop-update',
      requireInteraction: normalized.isNewOrder,
      silent: false,
      renotify: true,
      vibrate: normalized.isNewOrder ? [400, 200, 400, 200, 400] : [200, 100, 200],
    },
  };
}

function notifyOpenClients(title, body, orderId) {
  return self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
    clientList.forEach(function (client) {
      client.postMessage({
        type: 'NEW_ORDER_ALERT',
        orderId: orderId,
        title: title,
        body: body,
      });
    });
  });
}

function tryPlayAlertSoundInServiceWorker() {
  try {
    var audio = new Audio(alertSoundUrl());
    audio.loop = true;
    return audio.play().catch(function (err) {
      console.log('[firebase-messaging-sw.js] SW audio blocked:', err);
    });
  } catch (err) {
    console.log('[firebase-messaging-sw.js] SW audio unavailable:', err);
    return Promise.resolve();
  }
}

function showPushNotification(payload) {
  const built = buildNotificationPayload(payload);
  const tasks = [self.registration.showNotification(built.title, built.options)];

  if (built.isNewOrder) {
    tasks.push(storePendingOrderAlert(built.orderId));
    tasks.push(notifyOpenClients(built.title, built.body, built.orderId));
    tasks.push(tryPlayAlertSoundInServiceWorker());
  }

  return Promise.all(tasks);
}

messaging.onBackgroundMessage(function (payload) {
  console.log('[firebase-messaging-sw.js] onBackgroundMessage', payload);
  return showPushNotification(payload);
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const data = event.notification.data || {};
  const orderId = data.orderId || data.order_id || null;
  const targetUrl = self.location.origin + '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url.indexOf(self.location.origin) === 0 && 'focus' in client) {
          client.postMessage({
            type: 'NEW_ORDER_ALERT',
            orderId: orderId,
            fromNotificationClick: true,
          });
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(targetUrl).then(function (client) {
          if (client) {
            client.postMessage({
              type: 'NEW_ORDER_ALERT',
              orderId: orderId,
              fromNotificationClick: true,
            });
          }
        });
      }
    })
  );
});
