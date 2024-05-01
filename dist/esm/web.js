import { WebPlugin } from '@capacitor/core';
export class SubscriptionsWeb extends WebPlugin {
    setGoogleVerificationDetails(options) {
        console.info(options);
    }
    async echo(options) {
        return options;
    }
    async getProductDetails(options) {
        console.info(options);
        return {
            responseCode: -1,
            responseMessage: 'Incompatible with web',
        };
    }
    async purchaseProduct(options) {
        console.info(options);
        return {
            responseCode: -1,
            responseMessage: 'Incompatible with web',
        };
    }
    async getCurrentEntitlements() {
        return {
            responseCode: -1,
            responseMessage: 'Incompatible with web',
        };
    }
    async getLatestTransaction(options) {
        console.info(options);
        return {
            responseCode: -1,
            responseMessage: 'Incompatible with web',
        };
    }
    manageSubscriptions() {
    }
}
//# sourceMappingURL=web.js.map