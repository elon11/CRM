/**
 * @Class Name: LoanRequestController
 * @Description: Handles creation and retrieval of LoanRequest__c records from LWC.
 * @Created by: Elon Ifrach
 * @Created Date: 2025-12-06
 */
public with sharing class LoanRequestController {

    @AuraEnabled
    public static LoanRequest__c createLoanRequest(String customerName, Decimal loanAmount, String loanStatus) {
        if (String.isBlank(customerName)) {
            throw new AuraHandledException('Customer Name is required.');
        }

        // Find existing customer by name
        List<Customer__c> customers = [
            SELECT Id, Name, Status__c, Email__c
            FROM Customer__c
            WHERE Name = :customerName
            LIMIT 1
        ];
        if (customers.isEmpty()) {
            throw new AuraHandledException('Customer not found with name: ' + customerName);
        }

        Customer__c customer = customers[0];

        // Create LoanRequest__c record
        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = customer.Id,
            LoanAmount__c = loanAmount,
            LoanStatus__c = loanStatus
        );
        try {
            insert loan;
        } catch (DmlException de) {
            if (de.getMessage().contains('Loan Amount must be positive')) {
                throw de;
            }
            throw new AuraHandledException('Error creating loan request: ' + de.getMessage());
        }

        // Return full record (critical for LoanViewer)
        loan = [
            SELECT Id, LoanAmount__c, LoanStatus__c,
                   Customer__c, Customer__r.Name
            FROM LoanRequest__c
            WHERE Id = :loan.Id
            LIMIT 1
        ];

        return loan;
    }

    @AuraEnabled(cacheable=true)
    public static LoanRequest__c getLoanRequestById(Id loanId) {
        if (loanId == null) return null;

        return [
            SELECT Id, LoanAmount__c, LoanStatus__c,
                   Customer__c, Customer__r.Name
            FROM LoanRequest__c
            WHERE Id = :loanId
            LIMIT 1
        ];
    }
}
