// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dao{
  
 struct Investor {
    address payable  investoraddress;
    uint investmentAmount;
    uint shares;
  }

   struct proposal{
    uint id;
    string description;
    uint amountRequested;
    address  payable receipientaddress;
    uint voteCount;
    uint end;
    bool isExecuted;
   }
  
  mapping (address => Investor) public investors;
  mapping (address=>mapping (uint=>bool)) public isVoted; 
  mapping (uint=>proposal) public proposals;
  address[] public investorlist;
   
  uint public availablefunds;
  uint public contributionEndTime;
  uint public votetime;
  uint public quorum;
  uint public totalShares;
  uint public nextproposalId;
  address public manager; 

  constructor(uint _contributionEndTime, uint _votetime, uint _quorum) {
    require(_quorum>0 && _quorum<100,"Not valid values");
    votetime=_votetime;
    contributionEndTime=block.timestamp+_contributionEndTime;
    votetime = _votetime;
    quorum=_quorum;
    manager=msg.sender;
    
  }  

  modifier onlyInvestor(){
    require(investors[msg.sender].investoraddress != address(0),"You are not an investor");
  _;
  }

  modifier onlyManager(){
    require(msg.sender==manager,"You do not have the permission for this");
    _;
  }

    function contribute() payable public {
      require(contributionEndTime >= block.timestamp,"Contribution Time has Ended");
      require(msg.value>0,"Send more than 0 ether");
      uint shares = (msg.value/1000000000000000000);  // 1 Ether = 1 share
      
      if(investors[msg.sender].investoraddress == address(0)){   // A new Investor joining
         investors[msg.sender] = Investor(payable (msg.sender),msg.value,shares);
         investorlist.push(msg.sender);

      } else {   // This investor is an old investor (already contributed before also)
       investors[msg.sender].investmentAmount += msg.value;
       investors[msg.sender].shares += shares;
 
      }
      
      availablefunds += msg.value;
      totalShares += shares;
  }

    function redeemShares(uint _amount) public onlyInvestor{

      require(_amount>0,"Amount must be greater than 0");
      require(investors[msg.sender].shares>=_amount,"Not enough shares");
      require(availablefunds>_amount,"Not enough funds");
      
      investors[msg.sender].shares-=_amount;
      if(investors[msg.sender].shares==0){
        investors[msg.sender]=Investor(payable(address(0)),0,0);
      }
      availablefunds-=_amount;
      investors[msg.sender].investoraddress.transfer(_amount);

    }

    function TransferShares(address _to, uint _amount) public onlyInvestor{
     require(_amount>0,"Shares must be greater than 0");
     require(investors[msg.sender].shares >= _amount,"Not enough shares");

     investors[msg.sender].shares -= _amount;
     if(investors[msg.sender].shares==0){
        investors[msg.sender]=Investor(payable(address(0)),0,0);
      }
      if(investors[_to].investoraddress == address(0)){   // A new Investor joining
         investors[_to] = Investor(payable (_to),_amount,_amount);
         investorlist.push(_to);

      } else {   // This investor is an old investor (already contributed before also)
       investors[_to].investmentAmount += _amount;
       investors[_to].shares += _amount;
 
      }
     investors[_to].shares += _amount;
    }

    
  function proposalCreation(string calldata _description, uint _amountRequested, address payable _receipientaddress) public onlyManager{
   require(bytes(_description).length > 0,"cannot be empty");
   require(availablefunds> _amountRequested,"Not enough funds");
    
    proposals[nextproposalId]=proposal(nextproposalId,_description,_amountRequested,_receipientaddress,0,block.timestamp+votetime,false);
   nextproposalId++;
  }
   
   function voteProposal(uint _proposalId) public onlyInvestor{
    proposal storage proposal1 = proposals[_proposalId];
    require(investors[msg.sender].shares>0,"Only shareholders can vote");
    require(isVoted[msg.sender][_proposalId] == false,"You have already voted");
    require(proposal1.end>block.timestamp,"Voting time ended");
    require(proposal1.isExecuted==false,"It is already executed");
    
     isVoted[msg.sender][_proposalId]= true;
    proposal1.voteCount+= investors[msg.sender].shares;
   }

   function executeProposal(uint _proposalId) public onlyManager{
    proposal storage proposal1 = proposals[_proposalId];
    require(address(this).balance>=proposal1.amountRequested , "DAO does not have enough funds to execute this proposal");
    require(((proposal1.voteCount*100)/totalShares)>quorum,"Proposal does not have majority" );
    proposal1.isExecuted=true;
    availablefunds-=proposal1.amountRequested;
   proposal1.receipientaddress.transfer(proposal1.amountRequested);
   }

   function proposallist()public view returns(proposal[] memory){
    proposal[] memory proposalarr = new proposal[](nextproposalId-1);
    for (uint i=0;i<nextproposalId; i++) 
    {
      proposalarr[i] = proposals[i];
    }
    return proposalarr;
   }

   function getInvestors() public view returns(address[] memory){
    return  investorlist;
   }
}
   