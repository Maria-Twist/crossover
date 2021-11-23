/**
 * Created by Pavel Kovalevsky on 11/12/2020.
 */
({
    doInit : function(component) {
        var action = component.get("c.getInitialInfo");
        action.setParams({
            recId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            if (component.isValid() && response.getState() === "SUCCESS" && response.getReturnValue() !== null) {
                component.set('v.specialists', response.getReturnValue());

                console.log('response.getReturnValue()');
                console.log(response.getReturnValue());

				component.set('v.isAccessible', true);
                console.log('---init', response.getReturnValue().otherSpecs);
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "You don't have acess to this functionality",
                    "type": "error"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    sortData : function (component, fieldName, sortDirection) {
        console.log('sortttt', fieldName);
        var currentDir = component.get("v.arrowDirection");
        if (currentDir == 'arrowdown') {
            component.set("v.arrowDirection", 'arrowup');

        } else {
            component.set("v.arrowDirection", 'arrowdown');
            sortDirection = 'desc';
        }

        var data = component.get("v.specialists");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        console.log('---data', data);
        component.set("v.specialists", data);
    },

    sortBy : function (field, reverse, primer) {
        console.log('---sortBy');
        var key = primer ?
            function (x) {
                return primer(x.hasOwnProperty(field) ? (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : '#####')
            } :
        function (x) {
            return x.hasOwnProperty(field) ? (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : '#####'
        };
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },

    doSearch : function(component) {
        let specs = component.get("v.specialities");
        let zip = component.get("v.zip");
        if (!zip) {
            zip = '';
        }
        let city = component.get("v.city");
        if (!city) {
            city = '';
        }

        if (specs && (zip || city)) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Search",
                "message": specs + " within 20 miles of " + zip + " " + city
            });
            toastEvent.fire();
        }

        var action = component.get("c.getFilteredRecords");
        action.setParams({
            "recId" : component.get("v.recordId"),
            "zip" : component.get("v.zip"),
            "city" : component.get("v.city"),
            "specs" : component.get("v.specialities")
        });
        action.setCallback(this, function (response) {
            if (component.isValid() && response.getState() === "SUCCESS" && response.getReturnValue() !== null) {
                component.set('v.specialists', response.getReturnValue());
                component.set('v.selectedRow', null);
                console.log('---init', response.getReturnValue().otherSpecs);

                component.set('v.showSpinner', false);

            } else {
                //disable
            }
        });
        component.set('v.showSpinner', true);

        $A.enqueueAction(action);
    },

    saveRecord: function (component) {
        console.log('groupId: component.get("v.selectedGroupId")');
        console.log(component.get("v.selectedGroupId"));

        var action = component.get('c.updatePatientReferral');
        console.log('---selected in helper', component.get("v.selectedRow"));
        action.setParams({
            recId: component.get("v.recordId"),
            specId: component.get("v.selectedRow"),
            cost: component.get("v.selectedCost"),
            quan: component.get("v.selectedQuantity"),
            internal: component.get("v.selectedInternal"),
            provider: component.get("v.selectedProvider"),
            groupId: component.get("v.selectedGroupId")
        });

        component.set("v.selectedRow", null);
        action.setCallback(this, function (response) {
            if (component.isValid() && response.getState() === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The record has been updated successfully.",
                    "type": "success"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": response.getError(),
                    "type": "error"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
});