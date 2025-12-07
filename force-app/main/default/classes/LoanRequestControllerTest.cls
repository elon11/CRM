@IsTest
public class LoanRequestControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create a test customer
        Customer__c customer = new Customer__c(
            Name = 'Test Customer',
            Email__c = 'test@example.com',
            Phone__c = '1234567890',
            Status__c = 'New'
        );
        insert customer;
    }

    @IsTest
    static void testCreateLoanRequestSuccess() {
        Customer__c customer = [SELECT Id, Name FROM Customer__c WHERE Name = 'Test Customer' LIMIT 1];

        Test.startTest();
        // Call the controller method
        LoanRequest__c loan = LoanRequestController.createLoanRequest(customer.Name, 50000, 'Draft');
        insert loan;
        Id loanId = loan.Id;
        Test.stopTest();

        LoanRequest__c loan2 = [SELECT Id, Customer__c, LoanAmount__c, LoanStatus__c FROM LoanRequest__c WHERE Id = :loanId];
        System.assertEquals(customer.Id, loan2.Customer__c, 'Customer Id should match');
        System.assertEquals(50000, loan2.LoanAmount__c, 'Loan amount should match');
        System.assertEquals('Draft', loan2.LoanStatus__c, 'Loan status should match');
    }

    @IsTest
    static void testCreateLoanRequestBlankCustomerName() {
        Test.startTest();
        try {
            LoanRequestController.createLoanRequest('', 50000, 'Draft');
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Customer Name cannot be blank'), 'Exception message should indicate blank customer name');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateLoanRequestInvalidLoanAmount() {
        Customer__c customer = [SELECT Id, Name FROM Customer__c WHERE Name = 'Test Customer' LIMIT 1];

        Test.startTest();
        try {
            LoanRequestController.createLoanRequest(customer.Name, 0, 'Draft');
            System.assert(false, 'Exception should have been thrown for invalid loan amount');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Loan Amount must be greater than zero'), 'Exception message should indicate invalid loan amount');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateLoanRequestCustomerNotFound() {
        Test.startTest();
        try {
            LoanRequestController.createLoanRequest('Non Existing Customer', 10000, 'Draft');
            System.assert(false, 'Exception should have been thrown for non-existing customer');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Customer not found'), 'Exception message should indicate customer not found');
        }
        Test.stopTest();
    }
}
