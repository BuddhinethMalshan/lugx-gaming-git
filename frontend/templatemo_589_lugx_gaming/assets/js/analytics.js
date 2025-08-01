function generateShortUserId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
}

let userId = localStorage.getItem('user_id');
if (!userId) {
  userId = generateShortUserId();
  localStorage.setItem('user_id', userId);
}
console.log('Your user_id:', userId);

function sendEvent(eventType, page, target, depth) {
  const analyticsUrl = 'http://analytics.lugx.test/events';
  const timestamp = new Date().toISOString().slice(0, 19).replace('T', ' ');
  fetch(analyticsUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      event_type: eventType,
      page,
      target,
      depth,
      timestamp,
      user_id: userId
    })
  })
    .then(response => {
      if (response.ok) {
        console.log('Event sent:', { event_type: eventType });
        return response.json();
      }
      throw new Error('Failed to send event');
    })
    .then(data => console.log('Analytics response:', data))
    .catch(error => console.error('Error sending event:', error));
}

let maxScrollDepth = 0;
let pageStartTime = Date.now();

window.addEventListener('load', () => {
  sendEvent('page_view', window.location.pathname, 'page', 0);
});

document.querySelectorAll('button').forEach(button => {
  button.addEventListener('click', () => {
    sendEvent('click', window.location.pathname, button.id || 'button', 100);
  });
});

window.addEventListener('scroll', () => {
  const scrollTop = window.scrollY || document.documentElement.scrollTop;
  const scrollHeight = document.documentElement.scrollHeight - document.documentElement.clientHeight;
  const scrollPercentage = scrollHeight > 0 ? Math.round((scrollTop / scrollHeight) * 100) : 0;
  maxScrollDepth = Math.max(maxScrollDepth, scrollPercentage);
});

window.addEventListener('beforeunload', () => {
  const pageTimeSeconds = Math.round((Date.now() - pageStartTime) / 1000);
  sendEvent('scroll_depth', window.location.pathname, 'page', maxScrollDepth);
  sendEvent('page_time', window.location.pathname, 'page', pageTimeSeconds);
});
