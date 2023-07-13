importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

const firebaseConfig = {
  apiKey: "AIzaSyCaQ10VtjIbV9C7J5P9RJNjCzwjeB3NqP8",
  authDomain: "flutter-firebase-messagi-9565f.firebaseapp.com",
  projectId: "flutter-firebase-messagi-9565f",
  storageBucket: "flutter-firebase-messagi-9565f.appspot.com",
  messagingSenderId: "734289211847",
  appId: "1:734289211847:web:2348585c31b1cfd8e969e2",
  measurementId: "G-729PF8S4SD"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});