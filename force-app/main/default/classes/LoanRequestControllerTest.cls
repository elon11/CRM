@IsTest
public class LoanRequestControllerTest {

    @TestSetup
    static void setupTestData() {
   
        Customer__c customer1 = new Customer__c(
            Name = 'Test Customer 1',
            Status__c = 'New',
            Email__c = 'test1@example.com'
        );
        Customer__c customer2 = new Customer__c(
            Name = 'Test Customer 2',
            Status__c = 'New',
            Email__c = 'test2@example.com'
        );
        insert new List<Customer__c>{customer1, customer2};

        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = customer1.Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Draft'
        );
        insert loan;
    }

        @IsTest
    static void testCreateLoanRequest_Success() {
       
        Customer__c customer = [
            SELECT Id, Name, Email__c, Status__c
            FROM Customer__c
            WHERE Name = 'Test Customer 1'
            LIMIT 1
        ];

        Test.startTest();
        LoanRequest__c loan = LoanRequestController.createLoanRequest(customer.Name, 200000, 'Draft');
        Test.stopTest();

        System.assertNotEquals(null, loan.Id, 'LoanRequest Id should not be null');
        System.assertEquals(200000, loan.LoanAmount__c, 'Loan amount should match');
        System.assertEquals('Draft', loan.LoanStatus__c, 'Loan status should match');
        System.assertEquals(customer.Id, loan.Customer__c, 'Customer Id should match');

      
        LoanRequest__c fetched = [
            SELECT Id, Customer__c, Customer_Name__c
            FROM LoanRequest__c
            WHERE Id = :loan.Id
            LIMIT 1
        ];

      
        System.assertEquals(customer.Name, fetched.Customer_Name__c, 'Customer Name should match');
    }



    @IsTest
    static void testGetLoanRequestById_Success() {
        LoanRequest__c existingLoan = [SELECT Id FROM LoanRequest__c LIMIT 1];

        LoanRequest__c loan = LoanRequestController.getLoanRequestById(existingLoan.Id);

        System.assertNotEquals(null, loan, 'LoanRequest should not be null');
        System.assertEquals(existingLoan.Id, loan.Id, 'LoanRequest Id should match');
        System.assertNotEquals(null, loan.Customer__r.Name, 'Customer Name should be populated');
    }

    @IsTest
    static void testGetLoanRequestById_NullId() {
        LoanRequest__c loan = LoanRequestController.getLoanRequestById(null);
        System.assertEquals(null, loan, 'LoanRequest should be null for null Id');
    }
}
