var capacitorSubscriptions = (function (exports, core) {
    'use strict';

    const Subscriptions = core.registerPlugin('Subscriptions', {
        web: () => Promise.resolve().then(function () { return web; }).then(m => new m.SubscriptionsWeb()),
    });

    class SubscriptionsWeb extends core.WebPlugin {
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

    var web = /*#__PURE__*/Object.freeze({
        __proto__: null,
        SubscriptionsWeb: SubscriptionsWeb
    });

    exports.Subscriptions = Subscriptions;

    return exports;

})({}, capacitorExports);
//# sourceMappingURL=plugin.js.map
