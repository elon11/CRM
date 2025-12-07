import { LightningElement, track, api } from 'lwc';
import { registerListener, unregisterListener } from 'c/pubsub';
import getLoanRequestById from '@salesforce/apex/LoanRequestController.getLoanRequestById';

/**
 * @description: Component B - Displays loan request data received from loanForm component.
 *               Added capability to load data directly from Salesforce after refresh.
 * @createdBy: Elon Ifrach
 * @createdDate: 2025-12-06
 */
export default class LoanViewer extends LightningElement {
    @api loanId; // Allows parent or external input to specify which LoanRequest to load
    @track customerName = '';
    @track loanAmount;
    @track loanStatus = '';

    handleLoanCreated(loanData) {
        this.customerName = loanData.Customer__r ? loanData.Customer__r.Name : '';
        this.loanAmount = loanData.LoanAmount__c;
        this.loanStatus = loanData.LoanStatus__c;

        // 🔹 שמירת ה-Id ב-sessionStorage כדי לשמור על הנתונים אחרי רפרוש
        if (loanData.Id) {
            window.sessionStorage.setItem('lastLoanId', loanData.Id);
        }
    }

    loadLoanFromServer() {
        const loanIdToLoad = this.loanId || window.sessionStorage.getItem('lastLoanId');
        if (!loanIdToLoad) return;

        getLoanRequestById({ loanId: loanIdToLoad })
            .then(result => {
                this.handleLoanCreated(result);
            })
            .catch(error => {
                console.error('Error loading LoanRequest:', error);
            });
    }

    connectedCallback() {
        registerListener('loanCreated', this.handleLoanCreated, this);
        this.loadLoanFromServer();
    }

    disconnectedCallback() {
        unregisterListener('loanCreated', this.handleLoanCreated, this);
    }
}
