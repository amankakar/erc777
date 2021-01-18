

pragma solidity ^0.5.9;


interface IERC777 {
    function name() external view returns (string memory);
  function symbol() external view returns (string memory);
 function granularity() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function send(address recipient, uint256 amount, bytes calldata data) external;
    function burn(uint256 amount, bytes calldata data) external;
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function defaultOperators() external view returns (address[] memory);
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

pragma solidity ^0.5.9;
interface IERC777Recipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

pragma solidity ^0.5.9;
interface IERC777Sender {
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

pragma solidity ^0.5.9;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.5.9;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

pragma solidity ^0.5.9;

interface IERC1820Registry {
    function setManager(address account, address newManager) external;
    function getManager(address account) external view returns (address);
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);
    function updateERC165Cache(address account, bytes4 interfaceId) external;
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}
contract Bitcoinv1 is IERC777, IERC20 {

    using SafeMath for uint256;
    using Address for address;

    IERC1820Registry private _erc1820 = IERC1820Registry(0xC2c18315cDa0d04f4E7724215dD22Dc34E851565);

    string public mName;
    string public mSymbol;
    uint256 internal mGranularity;
    uint256 internal mTotalSupply;
    address public _ownerAddress;
    uint256 public ceilingSupply;
    uint8 public constant decimals = 18; // 18 decimal places, the same as ETH

    mapping(address => uint) internal mBalances;

    address[] internal mDefaultOperators;
    mapping(address => bool) internal mIsDefaultOperator;
    mapping(address => mapping(address => bool)) internal mRevokedDefaultOperator;
    mapping(address => mapping(address => bool)) internal mAuthorizedOperators;

    // keccak256("ERC777TokensSender")
    bytes32 constant private TOKENS_SENDER_INTERFACE_HASH = 0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;

    // keccak256("ERC777TokensRecipient")
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    // ERC20-allowances
    mapping (address => mapping (address => uint256)) private _allowances;

    /* -- constructor -- */
    // @notice constructor to create Lazarus Token

    constructor(       
        address[] memory _defaultOperators
) public {
        mName = "BITCOIN1";
        mSymbol = "EBTC1";
        mTotalSupply =  2000000000 ;
        ceilingSupply =  20000000000;
        _ownerAddress = msg.sender;
        mBalances[msg.sender] = mTotalSupply;
        mGranularity = 1;

        mDefaultOperators= _defaultOperators;
        for (uint256 i = 0 ; i < mDefaultOperators.length; i++){
            mIsDefaultOperator[mDefaultOperators[i]] = true;
        }

        // register interfaces
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

    // @onlyOwner modifier that can be used in define
    //function which only owner of the smartcontract can call
    modifier onlyOwner{
        require(msg.sender == _ownerAddress, "Sender not authorized");
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }
    function name() public view returns (string memory) {return mName;}

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {return mSymbol;}

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() public view returns (uint256) {return mGranularity;}

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {return mTotalSupply;}

    //@notice Return the account balance of some account
    //@param _tokenHolder Address for which the balance is returned
    //@return the balance of '_tokenAddress'
    function balanceOf(address _tokenHolder) public view returns (uint256) {return mBalances[_tokenHolder];}

    //@notice Return the list of default operators
    //@return the list of all the defaultOperators operators
    function defaultOperators() public view returns (address[] memory) {return mDefaultOperators; }

    /// @notice Send `_amount` of tokens to address `_to` passing `_data` to the recipient
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _data the data with send function
    function send(address _to, uint256 _amount, bytes calldata _data) external {
        doSend(msg.sender, msg.sender, _to, _amount, _data, "", true);
    }
    /**
    * @dev See `IERC20.transfer`.
    *
    * Unlike `send`, `recipient` is _not_ required to implement the `tokensReceived`
    * interface if it is a contract.
    *
    * Also emits a `Sent` event.
    */
    function transfer(address recipient, uint256 amount) external returns(bool){
        require(recipient != address(0), "ERC777: transfer to the zero address");

        address from = msg.sender;
        callSender(from, from, recipient, amount, "", "");

        move(from, from, recipient, amount, "", "");

        callRecipient(from, from, recipient, amount, "", "", false);

    }

    /// @notice Authorize a third party `_operator` to manage (send) `msg.sender`'s tokens.
    /// @param _operator The operator that wants to be Authorized
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender, "Cannot authorize yourself as an operator");
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = false;
        } else {
            mAuthorizedOperators[_operator][msg.sender] = true;
        }
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /// @notice Revoke a third party `_operator`'s rights to manage (send) `msg.sender`'s tokens.
    /// @param _operator The operator that wants to be Revoked
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender, "Cannot revoke yourself as an operator");
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = true;
        } else {
            mAuthorizedOperators[_operator][msg.sender] = false;
        }
        emit RevokedOperator(_operator, msg.sender);
    }

    /// @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder` address.
    /// @param _operator address to check if it has the right to manage the tokens
    /// @param _tokenHolder address which holds the tokens to be managed
    /// @return `true` if `_operator` is authorized for `_tokenHolder`
    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        return (_operator == _tokenHolder // solium-disable-line operator-whitespace
            || mAuthorizedOperators[_operator][_tokenHolder]
            || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder]));
    }

    /// @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _data Data generated by the user to be sent to the recipient
    /// @param _operatorData Data generated by the operator to be sent to the recipient
    function operatorSend(address _from, address _to, uint256 _amount, bytes calldata _data, bytes calldata _operatorData) external {
        require(isOperatorFor(msg.sender, _from), "Not an operator");
        doSend(msg.sender, _from, _to, _amount, _data, _operatorData, true);
    }

    /**
     * @dev See `IERC20.allowance`.
     *
     * Note that operator and allowance concepts are orthogonal: operators may
     * not have allowance, and accounts with allowance may not be operators
     * themselves.
     */
    function allowance(address holder, address spender) public view returns (uint256) {
        return _allowances[holder][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        address holder = msg.sender;
        approve(holder, spender, value);
        return true;
    }

    /**
    * @dev See `IERC20.transferFrom`.
    *
    * Note that operator and allowance concepts are orthogonal: operators cannot
    * call `transferFrom` (unless they have allowance), and accounts with
    * allowance cannot call `operatorSend` (unless they are operators).
    *
    * Emits `Sent` and `Transfer` events.
    */
    function transferFrom(address holder, address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");
        require(holder != address(0), "ERC777: transfer from the zero address");

        address spender = msg.sender;

        callSender(spender, holder, recipient, amount, "", "");

        move(spender, holder, recipient, amount, "", "");
        approve(holder, spender, _allowances[holder][spender].sub(amount));

        callRecipient(spender, holder, recipient, amount, "", "", false);

        return true;
    }

    function burn(uint256 _amount, bytes calldata _data) external {
        doBurn(msg.sender, msg.sender, _amount, _data, "");
    }

    function operatorBurn(address _tokenHolder, uint256 _amount, bytes calldata _data, bytes calldata _operatorData) external {
        require(isOperatorFor(msg.sender, _tokenHolder), "Not an operator");
        doBurn(msg.sender, _tokenHolder, _amount, _data, _operatorData);
    }

    /* -- Helper Functions -- */
    //
    /// @notice Internal function that ensures `_amount` is multiple of the granularity
    /// @param _amount The quantity that want's to be checked
    function requireMultiple(uint256 _amount) internal view {
        require(_amount % mGranularity == 0, "Amount is not a multiple of granualrity");
    }

    /// @notice Helper function actually performing the sending of tokens.
    /// @param _operator The address performing the send
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _data Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `ERC777tokensRecipient`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function doSend(address _operator, address _from, address _to, uint256 _amount, bytes memory _data, bytes memory _operatorData, bool _preventLocking) internal {
        requireMultiple(_amount);
        require(_from != address(0), "ERC777: send from 0x0");
        require(_to != address(0), "ERC777: send to 0x0");

        callSender(_operator, _from, _to, _amount, _data, _operatorData);

        move(_operator, _from, _to, _amount, _data, _operatorData);

        callRecipient(_operator, _from, _to, _amount, _data, _operatorData, _preventLocking);
    }

    /// @notice Helper function actually performing the burning of tokens.
    /// @param _operator The address performing the burn
    /// @param _tokenHolder The address holding the tokens being burn
    /// @param _amount The number of tokens to be burnt
    /// @param _data Data generated by the token holder
    /// @param _operatorData Data generated by the operator
    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes memory _data, bytes memory _operatorData) internal {
        require(_tokenHolder != address(0), "ERC777: burn from 0x0");
        callSender(_operator, _tokenHolder, address(0), _amount, _data, _operatorData);

        requireMultiple(_amount);
        require(balanceOf(_tokenHolder) >= _amount, "Not enough funds");

        mTotalSupply = mTotalSupply.sub(_amount);
        mBalances[_tokenHolder] = mBalances[_tokenHolder].sub(_amount);

        emit Burned(_operator, _tokenHolder, _amount, _data, _operatorData);
        emit Transfer(_tokenHolder, address(0), _amount);
    }

    /// @notice Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _operator The address performing the send or mint
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _data Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `ERC777TokensRecipient`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callRecipient(address _operator, address _from, address _to, uint256 _amount, bytes memory _data, bytes memory _operatorData, bool _preventLocking) internal {
        address recipientImplementation = _erc1820.getInterfaceImplementer(_to, TOKENS_RECIPIENT_INTERFACE_HASH);
        if (recipientImplementation != address(0)) {
            IERC777Recipient(recipientImplementation).tokensReceived(_operator, _from, _to, _amount, _data, _operatorData);
        } else if (_preventLocking) {
            require(!_to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }

    function move(address operator, address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) private {
        require(mBalances[from] >= amount, "Not enough funds");
        mBalances[from] = mBalances[from].sub(amount);
        mBalances[to] = mBalances[to].add(amount);

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    /// @notice Helper function that checks for IERC777Sender on the sender and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    ///  implementing `IERC777Sender`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callSender(address _operator, address _from, address _to, uint256 _amount, bytes memory _userData, bytes memory _operatorData ) internal {
        address senderImplementation = _erc1820.getInterfaceImplementer(_from, TOKENS_SENDER_INTERFACE_HASH);
        if (senderImplementation != address(0)) {
            IERC777Sender(senderImplementation).tokensToSend(_operator, _from, _to, _amount, _userData, _operatorData);
        }
    }

    function approve(address holder, address spender, uint256 value) private {
        // TODO: restore this require statement if this function becomes internal, or is called at a new callsite. It is
        // currently unnecessary.
        //require(holder != address(0), "ERC777: approve from the zero address");
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    /**
    * Transfer ownership of contract to another account
    * @param _newOwner the address of new owner of the smartcontract
    */
    function transferOwnership(address _newOwner) public onlyOwner returns(bool success){
        _ownerAddress = _newOwner;
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If a send hook is registered for `raccount`, the corresponding function
     * will be called with `operator`, `data` and `operatorData`.
     *
     * See `IERC777Sender` and `IERC777Recipient`.
     *
     * Emits `Sent` and `Transfer` events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the `tokensReceived`
     * interface.
     */
    function mintToken(address operator, address account, uint256 amount, bytes calldata userData, bytes calldata operatorData) external onlyOwner {
        require (mTotalSupply <= ceilingSupply, "Total Supply must be less than Ceiling Supply ");
        require(account != address(0), "ERC777: mint to the zero address");

        // Update state variables
        mTotalSupply = mTotalSupply.add(amount);
        mBalances[account] = mBalances[account].add(amount);

        callRecipient(operator, address(0), account, amount, userData, operatorData, true);

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    /**
     * Total mintableToken pending in the system
    */
    function mintableToken() external view returns(uint256 remaining){
        return ceilingSupply.sub(mTotalSupply);
    }

}