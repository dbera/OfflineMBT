#include "CoffeeMachine.h"
#include <iostream>

// Initializes the machine with the given configuration
void CoffeeMachine::SetUp(CMConfig& c) {
    config = c;
}

// Checks if the machine's display is ready (i.e., all ingredients are available)
bool CoffeeMachine::CheckDisplayIsReady() {
    return config.coffeeBeansAmount > 0 &&
        config.milkAmount > 0 &&
        config.teaAmount > 0 &&
        config.sugarAmount > 0;
}

// Adds an order to the list of orders
void CoffeeMachine::OrderItem(const Order& o) {
    deliveredItems = Items();
    orders.push_back(o);
}

bool CoffeeMachine::checkSufficientStockForOrders() {
    int coffeeBeansAmount = 0;
    int milkAmount = 0;
    int teaAmount = 0;
    int sugarAmount = 0;

    for (const auto& order : orders) {
        if (order.espressoInst._isInitialized) {
            if (order.espressoInst.strength == Strength::LOW) {
                coffeeBeansAmount += 10;
            }
            if (order.espressoInst.strength == Strength::MED) {
                coffeeBeansAmount += 20;
            }
            if (order.espressoInst.strength == Strength::HIGH) {
                coffeeBeansAmount += 30;
            }
        }
        if (order.capuccinoInst._isInitialized) {
            if (order.capuccinoInst.strength == Strength::LOW) {
                coffeeBeansAmount += 10;
            }
            if (order.capuccinoInst.strength == Strength::MED) {
                coffeeBeansAmount += 20;
            }
            if (order.capuccinoInst.strength == Strength::HIGH) {
                coffeeBeansAmount += 30;
            }
            if (order.capuccinoInst.milkRatio <= 0.1) {
                milkAmount += 10;
            }
            if (order.capuccinoInst.milkRatio <= 0.5 && order.capuccinoInst.milkRatio > 0.1) {
                milkAmount += 30;
            }
            if (order.capuccinoInst.milkRatio <= 1.0 && order.capuccinoInst.milkRatio > 0.5) {
                milkAmount += 50;
            }
            if (order.capuccinoInst.sugarRatio <= 0.1) {
                sugarAmount += 10;
            }
            if (order.capuccinoInst.sugarRatio <= 0.5 && order.capuccinoInst.sugarRatio > 0.1) {
                sugarAmount += 25;
            }
            if (order.capuccinoInst.sugarRatio <= 1.0 && order.capuccinoInst.sugarRatio > 0.5) {
                sugarAmount += 50;
            }
        }
        if (order.teaInst._isInitialized) {
            teaAmount += 20;
            if (order.teaInst.strength == Strength::LOW) {
                teaAmount += 10;
            }
            if (order.teaInst.strength == Strength::MED) {
                teaAmount += 20;
            }
            if (order.teaInst.strength == Strength::HIGH) {
                teaAmount += 30;
            }
            if (order.teaInst.sugarRatio <= 0.1) {
                sugarAmount += 10;
            }
            if (order.teaInst.sugarRatio <= 0.5 && order.teaInst.sugarRatio > 0.1) {
                sugarAmount += 25;
            }
            if (order.teaInst.sugarRatio <= 1.0 && order.teaInst.sugarRatio > 0.5) {
                sugarAmount += 50;
            }
        }
    }

    if (coffeeBeansAmount <= config.coffeeBeansAmount &&
        milkAmount <= config.milkAmount &&
        teaAmount <= config.teaAmount &&
        sugarAmount <= config.sugarAmount) { return true; }
    else { return false; }
}

// Computes the total cost of all initialized drinks in all orders
int CoffeeMachine::GetBalance() {
    int totalCost = 0;

    for (const auto& order : orders) {
        if (order.espressoInst._isInitialized) {
            totalCost += espressoCost;
        }
        if (order.capuccinoInst._isInitialized) {
            totalCost += capuccinoCost;
        }
        if (order.teaInst._isInitialized) {
            totalCost += teaCost;
        }
    }

    balance = totalCost - amountPaid;
    if (balance < 0) {
        balance = 0;
    }
    return balance;
}

// Deducts the payment amount from the balance, ensuring it doesn't go negative
// Returns true if payment was accepted and items delivered; false if balance was already zero
void CoffeeMachine::Pay(int amount) {
    GetBalance();
    balance -= amount;
    amountPaid += amount;

    if (balance < 0) {
        balance = 0;
    }

    // If balance is fully paid, update delivered items
    if (balance == 0) 
    {
        int coffeeBeansAmount = 0;
        int milkAmount = 0;
        int teaAmount = 0;
        int sugarAmount = 0;

        for (const auto& order : orders) {
            if (order.espressoInst._isInitialized) {
                if (order.espressoInst.strength == Strength::LOW) {
                    coffeeBeansAmount += 10;
                }
                if (order.espressoInst.strength == Strength::MED) {
                    coffeeBeansAmount += 20;
                }
                if (order.espressoInst.strength == Strength::HIGH) {
                    coffeeBeansAmount += 30;
                }
            }
            if (order.capuccinoInst._isInitialized) {
                if (order.capuccinoInst.strength == Strength::LOW) {
                    coffeeBeansAmount += 10;
                }
                if (order.capuccinoInst.strength == Strength::MED) {
                    coffeeBeansAmount += 20;
                }
                if (order.capuccinoInst.strength == Strength::HIGH) {
                    coffeeBeansAmount += 30;
                }
                if (order.capuccinoInst.milkRatio <= 0.1) {
                    milkAmount += 10;
                }
                if (order.capuccinoInst.milkRatio <= 0.5 && order.capuccinoInst.milkRatio > 0.1) {
                    milkAmount += 30;
                }
                if (order.capuccinoInst.milkRatio <= 1.0 && order.capuccinoInst.milkRatio > 0.5) {
                    milkAmount += 50;
                }
                if (order.capuccinoInst.sugarRatio <= 0.1) {
                    sugarAmount += 10;
                }
                if (order.capuccinoInst.sugarRatio <= 0.5 && order.capuccinoInst.sugarRatio > 0.1) {
                    sugarAmount += 25;
                }
                if (order.capuccinoInst.sugarRatio <= 1.0 && order.capuccinoInst.sugarRatio > 0.5) {
                    sugarAmount += 50;
                }
            }
            if (order.teaInst._isInitialized) {
                teaAmount += 20;
                if (order.teaInst.strength == Strength::LOW) {
                    teaAmount += 10;
                }
                if (order.teaInst.strength == Strength::MED) {
                    teaAmount += 20;
                }
                if (order.teaInst.strength == Strength::HIGH) {
                    teaAmount += 30;
                }
                if (order.teaInst.sugarRatio <= 0.1) {
                    sugarAmount += 10;
                }
                if (order.teaInst.sugarRatio <= 0.5 && order.teaInst.sugarRatio > 0.1) {
                    sugarAmount += 25;
                }
                if (order.teaInst.sugarRatio <= 1.0 && order.teaInst.sugarRatio > 0.5) {
                    sugarAmount += 50;
                }
            }
        }
        /*std::cout << " CB: " << config.coffeeBeansAmount << std::endl;
        std::cout << " MA: " << config.milkAmount << std::endl;
        std::cout << " TA: " << config.teaAmount << std::endl;
        std::cout << " SA: " << config.sugarAmount << std::endl;

        std::cout << " _CB: " << coffeeBeansAmount << std::endl;
        std::cout << " _MA: " << milkAmount << std::endl;
        std::cout << " _TA: " << teaAmount << std::endl;
        std::cout << " _SA: " << sugarAmount << std::endl;
        */
        if (coffeeBeansAmount <= config.coffeeBeansAmount &&
            milkAmount <= config.milkAmount &&
            teaAmount <= config.teaAmount &&
            sugarAmount <= config.sugarAmount) {

            config.coffeeBeansAmount -= coffeeBeansAmount;
            config.milkAmount -= milkAmount;
            config.teaAmount -= teaAmount;
            config.sugarAmount -= sugarAmount;

            deliveredItems = Items();  // Reset before counting

            for (const auto& order : orders) {
                if (order.espressoInst._isInitialized) {
                    deliveredItems.numEspresso += 1;
                }
                if (order.capuccinoInst._isInitialized) {
                    deliveredItems.numCapuccino += 1;
                }
                if (order.teaInst._isInitialized) {
                    deliveredItems.numTea += 1;
                }
            }
        }
    }
}

CMConfig CoffeeMachine::getCurrentIngredientLevels() {
    return config;
}

// Returns the delivered items
Items CoffeeMachine::GetDeliveredItems() {    
    return deliveredItems;
}
