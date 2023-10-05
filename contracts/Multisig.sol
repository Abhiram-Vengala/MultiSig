// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Multisig{
    event Deposit(address indexed sender , uint value);
    event Submit(uint indexed transactionId);
    event Approve(address indexed owner , uint indexed transactionId);
    event Revoke(address indexed owner,uint indexed transactionId );
    event Excecute(uint indexed transactionId);
    struct Transactions{
        address to;
        uint value;
        bool excecuted;
    }

    address[] public  owners;
    mapping (address=>bool)public isOwner;
    uint public requiredOwners;

    Transactions[] transactions;
    mapping(uint=>mapping (address=>bool)) public approved;

    modifier onlyOwner(){
        require(isOwner[msg.sender],"Should be an owner");
        _;
    }
    modifier TransactionExsists(uint _transactionId){
        require(_transactionId<transactions.length,"Transaction does not exsists");
        _;
    }
    modifier notApproved(uint _transactionId){
        require(!approved[_transactionId][msg.sender],"Transaction already approved");
        _;
    }
    modifier notExcecuted(uint _transactionId){
        require(!transactions[_transactionId].excecuted,"Transaction already excecuted");
        _;
    }
    function RequriedOwners (address[] memory _owners, uint _requiredOwners ) external {
        require(_owners.length>1,"Required more num of owners");
        require(_requiredOwners>0&&_requiredOwners<=_owners.length);
        for(uint i=0;i<_owners.length;i++){
            address  owner = _owners[i];
            require(owner!=address(0),"Invalid owner");
            require(!isOwner[owner],"owner is not unique");
            isOwner[owner]=true;
            owners.push(owner);
        }
        requiredOwners=_requiredOwners;
    }
    function getRequiredOwners() external view returns(uint){
        return requiredOwners;  
    }
    function getAddress() external view returns (address){
        return  address(this);
    }
    receive() external  payable {
        emit Deposit(msg.sender,msg.value);
    }

    function submit(address _to ) external payable  {
        transactions.push(Transactions({
            to :_to,
            value:msg.value,
            excecuted:false
        }));
        emit Submit(transactions.length-1);
    }
    function approve(uint _transactionId)external 
    onlyOwner
    TransactionExsists( _transactionId)
    notApproved(_transactionId)
    notExcecuted(_transactionId)
     {
         approved[_transactionId][msg.sender]=true;
         emit Approve(msg.sender,_transactionId);
    }
    function getApproval(uint _transactionId) private view returns (uint count){
        for(uint i;i< owners.length;i++){
           if( approved[_transactionId][owners[i]]){
               count+=1;
           }
        }
    }
    function excecute(uint _transactionId) external payable TransactionExsists( _transactionId)
    notExcecuted(_transactionId)
     {
         require(getApproval(_transactionId)>=requiredOwners,"approval<requried");

        transactions[_transactionId].excecuted = true;
       (bool success, )= transactions[_transactionId].to.call{ value: transactions[_transactionId].value}(" ");

       require(success,"not happening");
       emit Excecute(_transactionId);
     }
     function revoke(uint _transactionId)external  onlyOwner
    TransactionExsists( _transactionId)
    notExcecuted(_transactionId) {
         require(approved[_transactionId][msg.sender],"transaction not approved");
         approved[_transactionId][msg.sender]=true;

         emit Revoke(msg.sender,_transactionId);
     }
}