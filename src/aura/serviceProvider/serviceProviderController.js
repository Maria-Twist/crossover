({
    handleClick: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();

        let action = component.get("c.getPatient");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.patient", response.getReturnValue());
                let patient = component.get("v.patient");
                let fields = [];

                if (!patient.insurance) {
                    fields.push('Insurance');
                }

                if (patient.error) {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "type": "error",
                        "message": patient.error
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                } else if (fields.length > 0) {
                    let missedFields = fields.join(', ');

                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": "Please fill in the following fields: " + missedFields
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                } else {
                    let action = component.get("c.savePatientInfo");
                    action.setParams({
                        "patientString": JSON.stringify(component.get("v.patient"))
                    });
                    action.setCallback(this, function(response) {
                        let state = response.getState();
                        if (state === "SUCCESS") {
                            let urlEvent = $A.get("e.force:navigateToURL");
                            urlEvent.setParams({
                                'url': 'https://crossoverhealth--castlight.my.salesforce.com/idp/login?app=0sp7j00000000H7'
                            });
                            urlEvent.fire();
                            $A.get("e.force:closeQuickAction").fire();
                        } else {
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    });

                    $A.enqueueAction(action);
                }
            } else {
                console.log('getPatient FAILED');
            }
        });

        $A.enqueueAction(action);
    }
});