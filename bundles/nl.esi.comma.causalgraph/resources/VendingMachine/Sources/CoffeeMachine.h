#pragma once

#include <vector>

// Enum to represent strength levels for drinks
enum class Strength { LOW, MED, HIGH };

// Configuration class for the coffee machine's ingredient setup
class CMConfig {
public:
    int coffeeBeansAmount;
    int milkAmount;
    int teaAmount;
    int sugarAmount;

    CMConfig(int coffee = 0, int milk = 0, int tea = 0, int sugar = 0)
        : coffeeBeansAmount(coffee), milkAmount(milk), teaAmount(tea), sugarAmount(sugar) {}
};

// Espresso drink class
class Espresso {
public:
    Strength strength;
    bool _isInitialized;

    Espresso(Strength s = Strength::LOW, bool isInitialized = false) : strength(s), _isInitialized(isInitialized) {}
};

// Cappuccino drink class
class Capuccino {
public:
    double milkRatio;
    Strength strength;
    double sugarRatio;
    bool _isInitialized;

    Capuccino(double milk = 0.0, Strength strength = Strength::LOW, double sugar = 0.0, bool isInitialized = false)
        : milkRatio(milk), strength(strength), sugarRatio(sugar), _isInitialized(isInitialized) {}
};

// Tea drink class
class Tea {
public:
    Strength strength;
    double sugarRatio;
    bool _isInitialized;

    Tea(Strength strength = Strength::LOW, double sugar = 0.0, bool isInitialized = false)
        : strength(strength), sugarRatio(sugar), _isInitialized(isInitialized) {}
};

// Order class
class Order {
public:
    Espresso espressoInst;
    Capuccino capuccinoInst;
    Tea teaInst;

    Order(Espresso e = {}, Capuccino c = {}, Tea t = {})
        : espressoInst(e), capuccinoInst(c), teaInst(t) {}
};

// Items class to track delivered drinks
class Items {
public:
    int numEspresso = 0;
    int numCapuccino = 0;
    int numTea = 0;
};

// Main CoffeeMachine class
class CoffeeMachine {
public:
    int amountPaid = 0;

    void SetUp(CMConfig& c);
    bool CheckDisplayIsReady();
    void OrderItem(const Order& o);
    bool checkSufficientStockForOrders();
    int GetBalance();
    void Pay(int amount);
    Items GetDeliveredItems();
    CMConfig getCurrentIngredientLevels();

private:
    CMConfig config;
    std::vector<Order> orders;
    int balance = 0;
    Items deliveredItems;

    static constexpr int espressoCost = 2;
    static constexpr int capuccinoCost = 5;
    static constexpr int teaCost = 3;
};
