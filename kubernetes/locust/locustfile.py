"""
Locust load test scenarios for Google Microservices Demo (Online Boutique)

This script simulates realistic user behavior including:
- Browsing products
- Adding items to cart
- Completing checkout
- Viewing cart
- Setting currency preferences
"""

import random
import logging
from locust import HttpUser, task, between, events

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Sample product IDs from the microservices demo
PRODUCT_IDS = [
    "OLJCESPC7Z",  # Sunglasses
    "66VCHSJNUP",  # Tank Top
    "1YMWWN1N4O",  # Home & Kitchen
    "L9ECAV7KIM",  # Loafers
    "2ZYFJ3GM2N",  # Hairdryer
    "0PUK6V6EV0",  # Candle Holder
    "LS4PSXUNUM",  # Salt & Pepper Shakers
    "9SIQT8TOJO",  # City Bike
    "6E92ZMYYFZ",  # Air Plant
]

# Currencies supported by the app
CURRENCIES = ["USD", "EUR", "GBP", "JPY", "CAD"]


class OnlineBoutiqueUser(HttpUser):
    """
    Simulates a user browsing the Online Boutique store
    """

    # Wait between 1-5 seconds between tasks to simulate realistic user behavior
    wait_time = between(1, 5)

    # Store session data
    cart_items = []
    selected_currency = "USD"

    def on_start(self):
        """Called when a simulated user starts"""
        logger.info("New user session started")
        # Set random currency preference
        self.selected_currency = random.choice(CURRENCIES)
        self._set_currency()

    @task(5)
    def view_homepage(self):
        """View the homepage - most common action"""
        with self.client.get(
            "/",
            catch_response=True,
            name="Homepage"
        ) as response:
            if response.status_code == 200:
                response.success()
                logger.debug("Homepage loaded successfully")
            else:
                response.failure(f"Failed to load homepage: {response.status_code}")

    @task(10)
    def view_product(self):
        """View a random product detail page"""
        product_id = random.choice(PRODUCT_IDS)
        with self.client.get(
            f"/product/{product_id}",
            catch_response=True,
            name="View Product"
        ) as response:
            if response.status_code == 200:
                response.success()
                logger.debug(f"Viewed product: {product_id}")
            else:
                response.failure(f"Failed to view product: {response.status_code}")

    @task(3)
    def add_to_cart(self):
        """Add a random product to the cart"""
        product_id = random.choice(PRODUCT_IDS)
        quantity = random.randint(1, 3)

        with self.client.post(
            "/cart",
            data={
                "product_id": product_id,
                "quantity": quantity
            },
            catch_response=True,
            name="Add to Cart"
        ) as response:
            if response.status_code in [200, 302]:  # 302 is redirect after adding
                response.success()
                self.cart_items.append({"product_id": product_id, "quantity": quantity})
                logger.info(f"Added {quantity}x {product_id} to cart")
            else:
                response.failure(f"Failed to add to cart: {response.status_code}")

    @task(2)
    def view_cart(self):
        """View the shopping cart"""
        with self.client.get(
            "/cart",
            catch_response=True,
            name="View Cart"
        ) as response:
            if response.status_code == 200:
                response.success()
                logger.debug("Viewed cart")
            else:
                response.failure(f"Failed to view cart: {response.status_code}")

    @task(1)
    def checkout(self):
        """Complete the checkout process - least common but most important"""
        # Only checkout if we have items in cart
        if not self.cart_items:
            logger.debug("Cart empty, adding item before checkout")
            self.add_to_cart()

        checkout_data = {
            "email": f"test-user-{random.randint(1000, 9999)}@example.com",
            "street_address": f"{random.randint(100, 999)} Main St",
            "zip_code": f"{random.randint(10000, 99999)}",
            "city": random.choice(["San Francisco", "New York", "Seattle", "Boston"]),
            "state": random.choice(["CA", "NY", "WA", "MA"]),
            "country": "United States",
            "credit_card_number": "4432-8015-6152-0454",  # Test card
            "credit_card_expiration_month": "12",
            "credit_card_expiration_year": "2025",
            "credit_card_cvv": "123",
        }

        with self.client.post(
            "/cart/checkout",
            data=checkout_data,
            catch_response=True,
            name="Complete Checkout"
        ) as response:
            if response.status_code in [200, 302]:
                response.success()
                logger.info(f"Checkout completed successfully with {len(self.cart_items)} items")
                # Clear cart after successful checkout
                self.cart_items = []
            else:
                response.failure(f"Checkout failed: {response.status_code}")

    @task(1)
    def empty_cart(self):
        """Empty the shopping cart"""
        with self.client.post(
            "/cart/empty",
            catch_response=True,
            name="Empty Cart"
        ) as response:
            if response.status_code in [200, 302]:
                response.success()
                self.cart_items = []
                logger.debug("Cart emptied")
            else:
                response.failure(f"Failed to empty cart: {response.status_code}")

    def _set_currency(self):
        """Set currency preference"""
        with self.client.post(
            "/setCurrency",
            data={"currency_code": self.selected_currency},
            catch_response=True,
            name="Set Currency"
        ) as response:
            if response.status_code in [200, 302]:
                response.success()
                logger.info(f"Currency set to: {self.selected_currency}")
            else:
                response.failure(f"Failed to set currency: {response.status_code}")


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Called when the load test starts"""
    logger.info("=" * 60)
    logger.info("Starting load test for Online Boutique")
    logger.info(f"Target host: {environment.host}")
    logger.info("=" * 60)


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Called when the load test stops"""
    logger.info("=" * 60)
    logger.info("Load test completed")
    logger.info("=" * 60)


# Alternative: More aggressive user behavior for stress testing
class AggressiveUser(HttpUser):
    """
    Aggressive user that performs actions more rapidly
    Use this for stress testing
    """
    wait_time = between(0.5, 2)

    @task
    def rapid_browsing(self):
        """Rapidly browse multiple products"""
        for _ in range(3):
            product_id = random.choice(PRODUCT_IDS)
            self.client.get(f"/product/{product_id}", name="Rapid Browse")

    @task
    def add_multiple_items(self):
        """Add multiple items quickly"""
        for _ in range(2):
            product_id = random.choice(PRODUCT_IDS)
            self.client.post("/cart", data={
                "product_id": product_id,
                "quantity": random.randint(1, 5)
            }, name="Add Multiple")
