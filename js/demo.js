document.addEventListener('DOMContentLoaded', () => {
  const banners = [
    '/images/1.gif','/images/2.gif','/images/3.gif',
    '/images/4.gif','/images/5.gif','/images/6.gif'
  ];

  const img = document.getElementById('screenshot-image');
  let current = 0;

  function nextAnimation() {
    current = (current + 1) % banners.length;
    img.src = banners[current];
  }

  function startDemo() {
    nextAnimation();
    setInterval(nextAnimation, 4000);
  }

  setTimeout(startDemo, 300);
});
