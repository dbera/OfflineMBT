/*
#include <gtest/gtest.h>
#include "CoffeeMachine.h"

class CoffeeMachineSequenceTest : public ::testing::Test {
protected:
    CoffeeMachine machine;

    void SetUpMachine(int coffee, int milk, int tea, int sugar) {
        CMConfig config{ coffee, milk, tea, sugar };
        machine.SetUp(config);
    }
};

TEST_F(CoffeeMachineSequenceTest, DisplayReadyWithFullIngredients) {
    SetUpMachine(10, 10, 10, 10);
    EXPECT_TRUE(machine.CheckDisplayIsReady());
}

TEST_F(CoffeeMachineSequenceTest, DisplayNotReadyWithMissingMilk) {
    SetUpMachine(10, 0, 10, 10);
    EXPECT_FALSE(machine.CheckDisplayIsReady());
}

TEST_F(CoffeeMachineSequenceTest, FullOrderAndFullPayment) {
    SetUpMachine(10, 10, 10, 10);

    machine.OrderItem(Order(Espresso(Strength::HIGH, true), {}, {}));
    machine.OrderItem(Order({}, Capuccino(0.5, Strength::MED, 0.3, true), {}));
    machine.OrderItem(Order({}, {}, Tea(Strength::LOW, 0.2, true)));

    EXPECT_EQ(machine.GetBalance(), 2 + 5 + 3);

    EXPECT_FALSE(machine.Pay(5)); // Partial payment
    EXPECT_TRUE(machine.Pay(5));  // Remaining payment

    Items delivered = machine.GetDeliveredItems();
    EXPECT_EQ(delivered.numEspresso, 1);
    EXPECT_EQ(delivered.numCapuccino, 1);
    EXPECT_EQ(delivered.numTea, 1);
}

TEST_F(CoffeeMachineSequenceTest, FullOrderWithMidPaymentAndAdditionalOrders) {
    SetUpMachine(10, 10, 10, 10);

    // Initial orders
    Order o1(Espresso(Strength::HIGH, true), {}, {});
    Order o2({}, Capuccino(0.5, Strength::MED, 0.3, true), {});
    machine.OrderItem(o1);
    machine.OrderItem(o2);

    EXPECT_EQ(machine.GetBalance(), 2 + 5); // Initial balance: 7

    // First payment (partial)
    EXPECT_FALSE(machine.Pay(5)); // Remaining balance: 2

    // Add more orders after partial payment
    Order o3({}, {}, Tea(Strength::LOW, 0.2, true));
    Order o4(Espresso(Strength::MED, true), {}, {});
    machine.OrderItem(o3);
    machine.OrderItem(o4);

    EXPECT_EQ(machine.GetBalance(), 2 + 5 + 3 + 2 - 5); // Updated balance: 7

    // Second payment (full)
    EXPECT_TRUE(machine.Pay(10)); // Remaining balance: 0

    Items delivered = machine.GetDeliveredItems();
    EXPECT_EQ(delivered.numEspresso, 2);   // o1 and o4
    EXPECT_EQ(delivered.numCapuccino, 1);  // o2
    EXPECT_EQ(delivered.numTea, 1);        // o3
}


TEST_F(CoffeeMachineSequenceTest, MultipleEspressoOrdersWithOverpayment) {
    SetUpMachine(10, 10, 10, 10);

    machine.OrderItem(Order(Espresso(Strength::MED, true), {}, {}));
    machine.OrderItem(Order(Espresso(Strength::HIGH, true), {}, {}));

    EXPECT_EQ(machine.GetBalance(), 4); // 2 + 2

    EXPECT_TRUE(machine.Pay(10)); // Overpayment

    Items delivered = machine.GetDeliveredItems();
    EXPECT_EQ(delivered.numEspresso, 2);
    EXPECT_EQ(delivered.numCapuccino, 0);
    EXPECT_EQ(delivered.numTea, 0);
}

TEST_F(CoffeeMachineSequenceTest, NoInitializedDrinksShouldNotRequirePayment) {
    SetUpMachine(10, 10, 10, 10);

    machine.OrderItem(Order(Espresso(Strength::LOW, false), {}, {}));
    machine.OrderItem(Order({}, Capuccino(0.5, Strength::MED, 0.3, false), {}));

    EXPECT_EQ(machine.GetBalance(), 0);
    EXPECT_FALSE(machine.Pay(5)); // No payment needed

    Items delivered = machine.GetDeliveredItems();
    EXPECT_EQ(delivered.numEspresso, 0);
    EXPECT_EQ(delivered.numCapuccino, 0);
    EXPECT_EQ(delivered.numTea, 0);
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
*/

#include <gtest/gtest.h>
#include "CoffeeMachine.h"

class CoffeeMachineSequenceTest : public ::testing::Test {
protected:
    CoffeeMachine machine;

    void SetUpMachine(int coffee, int milk, int tea, int sugar) {
        CMConfig config{ coffee, milk, tea, sugar };
        machine.SetUp(config);
    }

    // Local constants for drink costs
    static constexpr int espressoCost = 2;
    static constexpr int capuccinoCost = 5;
    static constexpr int teaCost = 3;
};

TEST_F(CoffeeMachineSequenceTest, DisplayReadyWithFullIngredients) {
    SetUpMachine(10, 10, 10, 10);
    EXPECT_TRUE(machine.CheckDisplayIsReady());
}

TEST_F(CoffeeMachineSequenceTest, DisplayNotReadyWithMissingMilk) {
    SetUpMachine(10, 0, 10, 10);
    EXPECT_FALSE(machine.CheckDisplayIsReady());
}

// updated
TEST_F(CoffeeMachineSequenceTest, FullOrderAndFullPayment) {
    CMConfig config{ 100, 100, 100, 100};
    machine.SetUp(config);

    Order espressoOrder(Espresso(Strength::HIGH, true), {}, {});
    Order capuccinoOrder({}, Capuccino(0.5, Strength::MED, 0.3, true), {});
    Order teaOrder({}, {}, Tea(Strength::LOW, 0.2, true));
    
    std::vector<Order> orders;
    orders.push_back(espressoOrder);
    orders.push_back(capuccinoOrder);
    orders.push_back(teaOrder);

    machine.OrderItem(espressoOrder);
    machine.OrderItem(capuccinoOrder);
    machine.OrderItem(teaOrder);

    EXPECT_TRUE(machine.checkSufficientStockForOrders());

    int expectedBalance = espressoCost + capuccinoCost + teaCost;
    EXPECT_EQ(machine.GetBalance(), expectedBalance);

    int firstPay = 5;
    machine.Pay(firstPay); // Partial payment

    machine.Pay(expectedBalance - firstPay);  // Remaining payment

    Items delivered = machine.GetDeliveredItems();

    EXPECT_EQ(orders.size(), 3);
    EXPECT_EQ(delivered.numEspresso, 1);
    EXPECT_EQ(delivered.numCapuccino, 1);
    EXPECT_EQ(delivered.numTea, 1);

    EXPECT_EQ(config.coffeeBeansAmount - 50, machine.getCurrentIngredientLevels().coffeeBeansAmount);
    EXPECT_EQ(config.milkAmount - 30, machine.getCurrentIngredientLevels().milkAmount);
    EXPECT_EQ(config.sugarAmount - 50, machine.getCurrentIngredientLevels().sugarAmount);
    EXPECT_EQ(config.teaAmount - 30, machine.getCurrentIngredientLevels().teaAmount);
}

TEST_F(CoffeeMachineSequenceTest, RepeatedOrdersRunningOutofSupply) {
    SetUpMachine(100, 100, 100, 100);

    Order espressoOrder(Espresso(Strength::HIGH, true), {}, {});
    Order capuccinoOrder({}, Capuccino(0.5, Strength::MED, 0.3, true), {});
    Order teaOrder({}, {}, Tea(Strength::LOW, 0.2, true));

    std::vector<Order> orders;
    orders.push_back(espressoOrder);
    orders.push_back(capuccinoOrder);
    orders.push_back(teaOrder);

    machine.OrderItem(espressoOrder);
    machine.OrderItem(capuccinoOrder);
    machine.OrderItem(teaOrder);

    EXPECT_TRUE(machine.checkSufficientStockForOrders());

    int expectedBalance = espressoCost + capuccinoCost + teaCost;
    EXPECT_EQ(machine.GetBalance(), expectedBalance);

    int firstPay = 5;
    machine.Pay(firstPay); // Partial payment

    machine.Pay(expectedBalance - firstPay);  // Remaining payment

    Items delivered = machine.GetDeliveredItems();

    EXPECT_EQ(orders.size(), 3);
    EXPECT_EQ(delivered.numEspresso, 1);
    EXPECT_EQ(delivered.numCapuccino, 1);
    EXPECT_EQ(delivered.numTea, 1);

    // second ordering
    Order _espressoOrder(Espresso(Strength::HIGH, true), {}, {});
    Order _capuccinoOrder({}, Capuccino(0.5, Strength::MED, 0.3, true), {});

    // std::vector<Order> orders;
    orders.clear();
    orders.push_back(_espressoOrder);
    orders.push_back(_capuccinoOrder);

    machine.OrderItem(_espressoOrder);
    machine.OrderItem(_capuccinoOrder);

    EXPECT_FALSE(machine.checkSufficientStockForOrders());

    //int 
    expectedBalance = espressoCost + capuccinoCost;
    EXPECT_EQ(machine.GetBalance(), expectedBalance);

    //int 
    firstPay = 5;
    machine.Pay(firstPay); // Partial payment

    machine.Pay(expectedBalance - firstPay);  // Remaining payment

    //Items 
    delivered = machine.GetDeliveredItems();

    EXPECT_EQ(orders.size(), 2);
    EXPECT_EQ(delivered.numEspresso, 0);
    EXPECT_EQ(delivered.numCapuccino, 0);
    EXPECT_EQ(delivered.numTea, 0);
}

TEST_F(CoffeeMachineSequenceTest, NotEnoughStock) {
    SetUpMachine(10, 10, 10, 10);

    Order espressoOrder(Espresso(Strength::HIGH, true), {}, {});
    Order capuccinoOrder({}, Capuccino(0.5, Strength::MED, 0.3, true), {});
    Order teaOrder({}, {}, Tea(Strength::LOW, 0.2, true));

    std::vector<Order> orders;
    orders.push_back(espressoOrder);
    orders.push_back(capuccinoOrder);
    orders.push_back(teaOrder);

    machine.OrderItem(espressoOrder);
    machine.OrderItem(capuccinoOrder);
    machine.OrderItem(teaOrder);

    EXPECT_FALSE(machine.checkSufficientStockForOrders());

    int expectedBalance = espressoCost + capuccinoCost + teaCost;
    EXPECT_EQ(machine.GetBalance(), expectedBalance);

    int firstPay = 5;
    machine.Pay(firstPay); // Partial payment

    EXPECT_FALSE(machine.checkSufficientStockForOrders());

    machine.Pay(expectedBalance - firstPay);  // Remaining payment

    EXPECT_FALSE(machine.checkSufficientStockForOrders()); // even if payment is done!

    Items delivered = machine.GetDeliveredItems();

    EXPECT_EQ(orders.size(), 3);
    EXPECT_EQ(delivered.numEspresso, 0);   // o1 and o4
    EXPECT_EQ(delivered.numCapuccino, 0);  // o2
    EXPECT_EQ(delivered.numTea, 0);        // o3
}

TEST_F(CoffeeMachineSequenceTest, FullOrderWithMidPaymentAndAdditionalOrders) {
    SetUpMachine(100, 100, 100, 100);

    Order o1(Espresso(Strength::HIGH, true), {}, {});
    Order o2({}, Capuccino(0.5, Strength::MED, 0.3, true), {});
    
    std::vector<Order> orders;
    orders.push_back(o1);
    orders.push_back(o2);

    machine.OrderItem(o1);
    machine.OrderItem(o2);
    EXPECT_TRUE(machine.checkSufficientStockForOrders());

    int initialBalance = espressoCost + capuccinoCost;
    EXPECT_EQ(machine.GetBalance(), initialBalance);

    machine.Pay(5); // Partial payment

    Order o3({}, {}, Tea(Strength::LOW, 0.2, true));
    Order o4(Espresso(Strength::MED, true), {}, {});
    orders.push_back(o3);
    orders.push_back(o4);

    machine.OrderItem(o3);
    machine.OrderItem(o4);

    EXPECT_TRUE(machine.checkSufficientStockForOrders());

    int updatedBalance = espressoCost + capuccinoCost + teaCost + espressoCost - 5;
    EXPECT_EQ(machine.GetBalance(), updatedBalance);

    machine.Pay(updatedBalance); // Full payment

    Items delivered = machine.GetDeliveredItems();

    EXPECT_EQ(orders.size(), 4);
    EXPECT_EQ(delivered.numEspresso, 2);   // o1 and o4
    EXPECT_EQ(delivered.numCapuccino, 1);  // o2
    EXPECT_EQ(delivered.numTea, 1);        // o3
}

TEST_F(CoffeeMachineSequenceTest, MultipleEspressoOrdersWithOverpayment) {
    SetUpMachine(300, 300, 300, 300);

    Order o1(Espresso(Strength::MED, true), {}, {});
    Order o2(Espresso(Strength::HIGH, true), {}, {});
    std::vector<Order> orders;
    orders.push_back(o1);
    orders.push_back(o2);

    machine.OrderItem(o1);
    machine.OrderItem(o2);

    EXPECT_TRUE(machine.checkSufficientStockForOrders());

    int expectedBalance = espressoCost + espressoCost;
    EXPECT_EQ(machine.GetBalance(), expectedBalance);

    machine.Pay(10); // Overpayment
    
    Items delivered = machine.GetDeliveredItems();
    
    EXPECT_EQ(orders.size(), 2);
    EXPECT_EQ(delivered.numEspresso, 2);
    EXPECT_EQ(delivered.numCapuccino, 0);
    EXPECT_EQ(delivered.numTea, 0);
}

TEST_F(CoffeeMachineSequenceTest, EmployeesDoNotRequirePayment) {
    SetUpMachine(100, 100, 100, 100);

    Order o1(Espresso(Strength::LOW, false), {}, {});
    Order o2({}, Capuccino(0.5, Strength::MED, 0.3, false), {});
    std::vector<Order> orders;
    orders.push_back(o1);
    orders.push_back(o2);
    
    machine.OrderItem(o1);
    machine.OrderItem(o2);
    
    EXPECT_TRUE(machine.checkSufficientStockForOrders());

    EXPECT_EQ(machine.GetBalance(), 0);
    
    machine.Pay(5); // No payment needed

    EXPECT_TRUE(machine.checkSufficientStockForOrders());
    Items delivered = machine.GetDeliveredItems();
    
    EXPECT_EQ(orders.size(), 2);
    EXPECT_EQ(delivered.numEspresso, 0);
    EXPECT_EQ(delivered.numCapuccino, 0);
    EXPECT_EQ(delivered.numTea, 0);
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
