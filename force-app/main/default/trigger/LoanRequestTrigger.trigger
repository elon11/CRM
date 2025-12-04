trigger LoanRequestTrigger on LoanRequest__c (after insert, after update) {
    LoanRequestHandler.handleTrigger(Trigger.new, Trigger.oldMap);
}
