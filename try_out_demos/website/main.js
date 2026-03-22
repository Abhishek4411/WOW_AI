// Sample data for jute bags (will be replaced with real data from backend later)
const products = [
  {
    id: 1,
    name: 'Eco-Friendly Tote Bag',
    description: 'A stylish and sustainable eco-friendly tote bag made from 100% natural jute.',
    price: 25.0,
    image: 'https://images.unsplash.com/photo-1590080877777-8f2cd93c5822?auto=format&fit=crop&w=600&q=80'
  },
  {
    id: 2,
    name: 'Jute Backpack',
    description: 'Durable and spacious jute backpack perfect for everyday use.',
    price: 45.0,
    image: 'https://images.unsplash.com/photo-1609023250015-25a4aa324bdb?auto=format&fit=crop&w=600&q=80'
  },
  {
    id: 3,
    name: 'Handmade Jute Clutch',
    description: 'Elegant handmade jute clutch for special occasions.',
    price: 30.0,
    image: 'https://images.unsplash.com/photo-1593032457861-7cd46f744615?auto=format&fit=crop&w=600&q=80'
  },
  {
    id: 4,
    name: 'Jute Shopping Bag with Handles',
    description: 'Eco-friendly shopping bag with strong handles for easy carrying.',
    price: 20.0,
    image: 'https://images.unsplash.com/photo-1618401478047-a492e7682d63?auto=format&fit=crop&w=600&q=80'
  }
];

// Globals for cart and current view
let cart = [];

// Utility functions
function $(selector) {
  return document.querySelector(selector);
}

// Render products list
function renderProducts() {
  const container = $('.products-container');
  container.innerHTML = '';
  products.forEach(product => {
    const productDiv = document.createElement('div');
    productDiv.className = 'product-item';
    productDiv.innerHTML = `
      <img src="${product.image}" alt="${product.name}" />
      <h3>${product.name}</h3>
      <p>${product.description}</p>
      <p><strong>Price: $${product.price.toFixed(2)}</strong></p>
    `;
    productDiv.addEventListener('click', () => {
      showProductDetail(product.id);
    });
    container.appendChild(productDiv);
  });
}

// Show product detail
function showProductDetail(productId) {
  const product = products.find(p => p.id === productId);
  if (!product) return;

  $('#product-listings').classList.add('hidden');
  $('#product-detail').classList.remove('hidden');

  const detailContent = $('.product-detail-content');
  detailContent.innerHTML = `
    <img src="${product.image}" alt="${product.name}" style="width:100%; border-radius: 10px; margin-bottom: 15px;" />
    <h3>${product.name}</h3>
    <p>${product.description}</p>
    <p><strong>Price: $${product.price.toFixed(2)}</strong></p>
    <button id="add-to-cart">Add to Cart</button>
  `;

  $('#add-to-cart').addEventListener('click', () => {
    addToCart(product);
  });
}

// Add product to cart
function addToCart(product) {
  const existing = cart.find(item => item.id === product.id);
  if (existing) {
    existing.quantity += 1;
  } else {
    cart.push({ ...product, quantity: 1 });
  }
  alert(`${product.name} added to cart.`);
}

// Show shopping cart
function showCart() {
  $('#product-listings').classList.add('hidden');
  $('#product-detail').classList.add('hidden');
  $('#user-account').classList.add('hidden');
  $('#checkout').classList.add('hidden');
  $('#shopping-cart').classList.remove('hidden');

  const cartItems = $('.cart-items');
  cartItems.innerHTML = '';

  if (cart.length === 0) {
    cartItems.innerHTML = '<p>Your cart is empty.</p>';
    return;
  }

  cart.forEach(item => {
    const itemDiv = document.createElement('div');
    itemDiv.className = 'cart-item';
    itemDiv.innerHTML = `
      <img src="${item.image}" alt="${item.name}" />
      <div class="cart-item-details">
        <h4>${item.name}</h4>
        <p>Quantity: ${item.quantity}</p>
        <p>Price: $${item.price.toFixed(2)}</p>
      </div>
      <button data-id="${item.id}">Remove</button>
    `;
    itemDiv.querySelector('button').addEventListener('click', (e) => {
      const id = parseInt(e.target.getAttribute('data-id'));
      removeFromCart(id);
      showCart();
    });
    cartItems.appendChild(itemDiv);
  });
}

// Remove item from cart
function removeFromCart(productId) {
  cart = cart.filter(item => item.id !== productId);
}

// Show user account section
function showUserAccount() {
  $('#product-listings').classList.add('hidden');
  $('#product-detail').classList.add('hidden');
  $('#shopping-cart').classList.add('hidden');
  $('#checkout').classList.add('hidden');
  $('#user-account').classList.remove('hidden');
}

// Show about us section
function showAboutUs() {
  $('#product-listings').classList.add('hidden');
  $('#product-detail').classList.add('hidden');
  $('#shopping-cart').classList.add('hidden');
  $('#checkout').classList.add('hidden');
  $('#user-account').classList.add('hidden');
  $('#about-us').scrollIntoView({ behavior: 'smooth' });
}

// Show checkout section
function showCheckout() {
  if (cart.length === 0) {
    alert('Your cart is empty. Add products before checkout.');
    return;
  }
  $('#product-listings').classList.add('hidden');
  $('#product-detail').classList.add('hidden');
  $('#shopping-cart').classList.add('hidden');
  $('#user-account').classList.add('hidden');
  $('#checkout').classList.remove('hidden');
}

// Hide all main sections except product listings
function showProductListings() {
  $('#product-listings').classList.remove('hidden');
  $('#product-detail').classList.add('hidden');
  $('#shopping-cart').classList.add('hidden');
  $('#checkout').classList.add('hidden');
  $('#user-account').classList.add('hidden');
}

// Initialize event listeners
function initEventListeners() {
  document.getElementById('back-to-list').addEventListener('click', showProductListings);
  document.getElementById('checkout-button').addEventListener('click', showCheckout);

  document.querySelector('nav ul').addEventListener('click', (e) => {
    e.preventDefault();
    if (e.target.tagName === 'A') {
      const href = e.target.getAttribute('href');
      if (href === '#product-listings') showProductListings();
      else if (href === '#about-us') showAboutUs();
      else if (href === '#user-account') showUserAccount();
      else if (href === '#shopping-cart') showCart();
    }
  });

  document.getElementById('checkout-form').addEventListener('submit', (e) => {
    e.preventDefault();
    alert('Order placed. Thank you!');
    cart = [];
    showProductListings();
  });

  document.getElementById('login-form').addEventListener('submit', (e) => {
    e.preventDefault();
    alert('Login functionality not implemented yet.');
  });
}

// Initialization
window.addEventListener('DOMContentLoaded', () => {
  renderProducts();
  initEventListeners();
});
