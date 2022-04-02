// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HealthContract {
    OwnedToken userToken;
    uint fundSum = 0;
    struct User {
        uint rating;
        uint requestedAmount
    }

    User[] public userQueue;
    mapping (address => uint) public balances;

    constructor(bytes32[] memory userNames, uint userRating, uint requestedAmount) {
        user = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit UserSet(address(0), user);
        userToken = OwnedToken(user);

        for (uint i = 0; i < userNames.length; i++) {
            userQueue.push(User({
                rating: userRating;
                requestedAmount: requestedAmount;
            }));
        }
    }
    
    /**
     * Used in UI for users to get their own address
     */
    function getUser() external view returns (address) {
        return user;
    }

    function transferToUser(address recipient, uint amount) {
        // Only the current owner can transfer the token.
        if (msg.sender != owner) return;

        // Check if sufficient balance
        require(amount <= balances[msg.sender], "Insufficient balance.");

        // We ask the creator contract if the transfer
        // should proceed by using a function of the
        // `TokenCreator` contract defined below. If
        // the call fails (e.g. due to out-of-gas),
        // the execution also fails here.
        if (creator.isTokenTransferOK(owner, recipient))
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
            fundSum += amount;
            emit Transfer(msg.sender, receiver, amount);
    }

    function isFulfilled() {
        if (fundSum == userQueue[0].requestedAmount) {
            fundSum = 0;
            userQueue.pop(0);
        }
    }
}

contract OwnedToken {
    // `TokenCreator` is a contract type that is defined below.
    // It is fine to reference it as long as it is not used
    // to create a new contract.
    TokenCreator creator;
    address owner;
    bytes32 name;

    // This is the constructor which registers the
    // creator and the assigned name.
    constructor(bytes32 name_) {
        // State variables are accessed via their name
        // and not via e.g. `this.owner`. Functions can
        // be accessed directly or through `this.f`,
        // but the latter provides an external view
        // to the function. Especially in the constructor,
        // you should not access functions externally,
        // because the function does not exist yet.
        // See the next section for details.
        owner = msg.sender;

        // We perform an explicit type conversion from `address`
        // to `TokenCreator` and assume that the type of
        // the calling contract is `TokenCreator`, there is
        // no real way to verify that.
        // This does not create a new contract.
        creator = TokenCreator(msg.sender);
        name = name_;
    }

    function changeName(bytes32 newName) public {
        // Only the creator can alter the name.
        // We compare the contract based on its
        // address which can be retrieved by
        // explicit conversion to address.
        if (msg.sender == address(creator))
            name = newName;
    }

    function transfer(address newOwner) public {
        // Only the current owner can transfer the token.
        if (msg.sender != owner) return;

        // We ask the creator contract if the transfer
        // should proceed by using a function of the
        // `TokenCreator` contract defined below. If
        // the call fails (e.g. due to out-of-gas),
        // the execution also fails here.
        if (creator.isTokenTransferOK(owner, newOwner))
            owner = newOwner;
    }
}

contract TokenCreator {
    function createToken(bytes32 name)
        public
        returns (OwnedToken tokenAddress)
    {
        // Create a new `Token` contract and return its address.
        // From the JavaScript side, the return type
        // of this function is `address`, as this is
        // the closest type available in the ABI.
        return new OwnedToken(name);
    }

    function changeName(OwnedToken tokenAddress, bytes32 name) public {
        // Again, the external type of `tokenAddress` is
        // simply `address`.
        tokenAddress.changeName(name);
    }

    // Perform checks to determine if transferring a token to the
    // `OwnedToken` contract should proceed
    function isTokenTransferOK(address currentOwner, address newOwner)
        public
        pure
        returns (bool ok)
    {
        // Check an arbitrary condition to see if transfer should proceed
        return keccak256(abi.encodePacked(currentOwner, newOwner))[0] == 0x7f;
    }
}