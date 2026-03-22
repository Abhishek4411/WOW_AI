document.addEventListener('DOMContentLoaded', () => {
  // Basic animation for the hero section button
  const button = document.querySelector('.button');
  if(button) {
    button.addEventListener('mouseenter', () => {
      button.style.transform = 'scale(1.1)';
      button.style.transition = 'transform 0.3s ease';
    });
    button.addEventListener('mouseleave', () => {
      button.style.transform = 'scale(1)';
    });
  }
});
