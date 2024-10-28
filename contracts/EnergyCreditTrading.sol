// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnergyCreditTrading {
    struct EnergyCredit {
        uint256 amount;
        address source;
        uint256 timestamp;
        string sourceType; // e.g., "solar", "wind", "hydro"
        bool isVerified;
    }

    struct Order {
        uint256 creditAmount;
        uint256 pricePerCredit;
        address seller;
        bool isActive;
    }

    // State variables
    mapping(address => uint256) public balances;
    mapping(address => EnergyCredit[]) public creditHistory;
    mapping(uint256 => Order) public sellOrders;
    uint256 public totalCredits;
    uint256 public orderCount;
    address public admin;
    
    // Events
    event CreditsMinted(address indexed source, uint256 amount, string sourceType);
    event CreditsTransferred(address indexed from, address indexed to, uint256 amount);
    event OrderCreated(uint256 indexed orderId, address seller, uint256 amount, uint256 price);
    event OrderFulfilled(uint256 indexed orderId, address buyer, address seller, uint256 amount);
    
    constructor() {
        admin = msg.sender;
        totalCredits = 0;
        orderCount = 0;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    // Function to mint new energy credits (only by verified sources)
    function mintCredits(
        uint256 _amount,
        string memory _sourceType
    ) external {
        require(_amount > 0, "Amount must be greater than 0");
        
        balances[msg.sender] += _amount;
        totalCredits += _amount;
        
        EnergyCredit memory newCredit = EnergyCredit({
            amount: _amount,
            source: msg.sender,
            timestamp: block.timestamp,
            sourceType: _sourceType,
            isVerified: true
        });
        
        creditHistory[msg.sender].push(newCredit);
        emit CreditsMinted(msg.sender, _amount, _sourceType);
    }
    
    // Function to create a sell order
    function createSellOrder(
        uint256 _creditAmount,
        uint256 _pricePerCredit
    ) external {
        require(balances[msg.sender] >= _creditAmount, "Insufficient credits");
        require(_creditAmount > 0, "Amount must be greater than 0");
        require(_pricePerCredit > 0, "Price must be greater than 0");
        
        orderCount++;
        sellOrders[orderCount] = Order({
            creditAmount: _creditAmount,
            pricePerCredit: _pricePerCredit,
            seller: msg.sender,
            isActive: true
        });
        
        emit OrderCreated(orderCount, msg.sender, _creditAmount, _pricePerCredit);
    }
    
    // Function to buy credits from a sell order
    function buyCredits(uint256 _orderId) external payable {
        Order storage order = sellOrders[_orderId];
        require(order.isActive, "Order is not active");
        require(msg.value == order.creditAmount * order.pricePerCredit, "Incorrect payment amount");
        
        address seller = order.seller;
        uint256 amount = order.creditAmount;
        
        // Transfer credits
        balances[seller] -= amount;
        balances[msg.sender] += amount;
        
        // Transfer payment to seller
        payable(seller).transfer(msg.value);
        
        // Update order status
        order.isActive = false;
        
        emit CreditsTransferred(seller, msg.sender, amount);
        emit OrderFulfilled(_orderId, msg.sender, seller, amount);
    }
    
    // Function to view credit history for an address
    function getCreditHistory(address _address) external view returns (EnergyCredit[] memory) {
        return creditHistory[_address];
    }
    
    // Function to verify credit source (admin only)
    function verifySource(address _source) external onlyAdmin {
        for (uint i = 0; i < creditHistory[_source].length; i++) {
            creditHistory[_source][i].isVerified = true;
        }
    }
    
    // Function to get active orders
    function getActiveOrders() external view returns (uint256[] memory) {
        uint256[] memory activeOrders = new uint256[](orderCount);
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= orderCount; i++) {
            if (sellOrders[i].isActive) {
                activeOrders[activeCount] = i;
                activeCount++;
            }
        }
        
        return activeOrders;
    }
}