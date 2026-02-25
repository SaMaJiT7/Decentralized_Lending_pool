// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lending {
    uint256 public totalLenderPrincipal;
    uint256 public constant ANNUAL_INTEREST_RATE = 10;

    //Establishing the Event Logs
    event Deposited(address indexed lender, uint256 amount, uint256 newPoolTotal);
    event Withdrawn(address indexed lender, uint256 amount);
    event Borrowed(address indexed borrower, uint256 principal, uint256 interestDue, uint256 dueTimestamp);
    event Repaid(address indexed borrower, uint256 totalRepaid, uint256 interestPaid);
    event DefaultDetected(address indexed borrower, uint256 amountOwed, uint256 overdueBy);

    struct Loan {
        address borrower;
        uint256 principal;
        uint256 interestRate;
        uint256 borrowedAt;
        uint256 dueAt;
        bool repaid;
    }

    mapping(address => uint256) public lenderDeposits;
    mapping(address => Loan) public activeLoans;
    mapping(address => bool) public hasActiveLoan;

    // deposit()
    function deposit() payable external {
        require(msg.value > 0, "The Deposit Amount Must be Greater than 0");
        lenderDeposits[msg.sender] += msg.value;
        totalLenderPrincipal += msg.value;

        emit Deposited(msg.sender,msg.value,address(this).balance);
    }

    // withdraw()
    function withdraw(uint256 amount) external {
       require(lenderDeposits[msg.sender] >= amount, "Insufficient Balance");
       // total balance in the account/pool.
       uint256 totalpoolamount = address(this).balance;

       //proportional amount to get
       uint256 proportionalamt = (amount * totalpoolamount)/totalLenderPrincipal;

       //Taking in mind for the liquidity of pool.
       require(address(this).balance >= proportionalamt, "Insufficient Balance in the pool");

       //updating the amount and totalpool
       lenderDeposits[msg.sender] -= amount;
       totalLenderPrincipal -= amount;

       emit Withdrawn(msg.sender, amount);

       (bool success, ) = payable(msg.sender).call{value: proportionalamt}("");
       require(success, "Transfer failed");
    }

    // borrow()
    function borrow(uint256 amount,uint256 durationDays) external {
        //checking whether the user asking already have loan or not.
        require(!hasActiveLoan[msg.sender], "You already have an active loan");
        // 2. Check if pool has sufficient liquidity
        require(address(this).balance >= amount, "Insufficient pool liquidity");

        //Activate the loan contract
        activeLoans[msg.sender] = Loan({
            borrower: msg.sender,
            principal: amount,
            interestRate: ANNUAL_INTEREST_RATE,
            borrowedAt: block.timestamp,
            dueAt: block.timestamp + (durationDays * 1 days),
            repaid: false
        });
        
        //updating that user has an active loan.
        hasActiveLoan[msg.sender] = true;

        emit Borrowed(msg.sender, amount, 10, block.timestamp + (durationDays * 1 days));

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to transfer funds");

    }

    // repay()
    function repay() payable external {
        Loan storage loan = activeLoans[msg.sender];
        require(hasActiveLoan[msg.sender],"No Active loan");

        //time from when loan was taken.
        uint256 secondsElapsed = block.timestamp - loan.borrowedAt;

        //The Interest on the principal amount taken.
        uint256 interest = (loan.principal * loan.interestRate * secondsElapsed)/ (365 days * 100);

        //Total amount to repay
        uint256 totalamt = loan.principal + interest;

        // Requirement: Repayment must cover exactly principal + accrued interest
        require(msg.value == totalamt, "Incorrect repayment amount");
        

        // IMPORTANT: Add the interest to the global principal so lenders can withdraw it proportionally
        totalLenderPrincipal += interest;

        //updating the loan contract
        hasActiveLoan[msg.sender] = false;
        loan.repaid = true;

        emit Repaid(msg.sender, totalamt, interest);
    }

    //checking whether it is overdue and then if yes then throw DefaultDetected.
    function checkDefault(address borrower) public{
        //check whether there is any active loan for the user.
        bool isActive = hasActiveLoan[borrower];
        require(isActive,"You have no Active Loan now.");

        //get the details of the loan.
        Loan storage loan = activeLoans[borrower];

        //checking the condition for the overdue.
        if(block.timestamp > loan.dueAt && !loan.repaid){
            uint256 secondsElasped = block.timestamp - loan.borrowedAt;
            uint256 interest = (loan.principal * loan.interestRate * secondsElasped)/(365 days * 100);
            uint256 totalOwned = loan.principal + interest;
            uint256 overdueBy = block.timestamp - loan.dueAt;

            emit DefaultDetected(borrower, totalOwned, overdueBy);
        }
    }

    //returns total ETH in the contract.
    function getPoolBalance() public view returns(uint256){
        return address(this).balance;
    }


    //returns the full Loan Struct for the given Borrower.
    function getLoan(address borrower) public view returns(Loan memory){
        require(hasActiveLoan[borrower],"You Currently dont have any Active Loans to View.");
        Loan storage loan = activeLoans[borrower];
        return loan;
    }
}