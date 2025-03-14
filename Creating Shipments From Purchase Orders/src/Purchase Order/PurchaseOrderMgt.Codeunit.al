codeunit 50008 "Create From Purch Order SCDNVN"
{
    Access = Internal;
    TableNo = "Purchase Header";
    Permissions = tabledata "Purchase Line" = M;

    trigger OnRun()
    begin
        CreateShipment(Rec);
    end;

    /// <summary>
    /// This is the starting point for creating Sendcloud shipments based on a purchase document. 
    /// This function will create a Sendcloud shipment for all lines on this document. 
    /// </summary>
    /// <param name="PurchaseHeader"></param>
    /// <returns></returns>
    internal procedure CreateShipment(var PurchaseHeader: Record "Purchase Header"): Record "Shipment Header SCNVN";
    var
        PurchaseLine: Record "Purchase Line";
        ShipmentHeader: Record "Shipment Header SCNVN";
        Parcel: Record "Parcel SCNVN";
        ShipmentMethodCode: Code[10];
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
        ShipToType: Enum "Ship-to Type SCNVN";
        AccumulatedWeight: Decimal;
    begin
        Init();

        ShipmentMethodCode := PurchaseHeader."Shipment Method Code";

        //Our purchase document does not have values for shipping agent and service, so additional code is needed to determine the right codes
        ShippingAgentCode := 'DHL';
        ShippingAgentServiceCode := 'STANDARD';

        //Create a Sendcloud Shipment Header for this purchase order.
        //As the source we provide our purchase order record. The recordid will be stored on our Sendcloud shipment just for reference. 
        ShipmentHeader := ShipmentAPI.CreateHeader(ShipToType::Vendor, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor Name", PurchaseHeader."Buy-from Contact", PurchaseHeader."Buy-from Address", PurchaseHeader."Buy-from Address 2",
        PurchaseHeader."Buy-from City", PurchaseHeader."Buy-from Post Code", PurchaseHeader."Buy-from County", PurchaseHeader."Buy-from Country/Region Code", 'some@email.com', '020-12345678',
        PurchaseHeader."Vendor Order No.", 'SOME REF', PurchaseHeader, 0, 0);

        //Now that we have a header, we'll also add 1 parcel, based on the information from our sendcloud shipment header and sales header.
        Parcel := ShipmentAPI.CreateParcel(ShipmentHeader, PurchaseHeader, PurchaseHeader."Location Code", ShipmentMethodCode, ShippingAgentCode, ShippingAgentServiceCode);

        //Get all sales order lines, and gather unique sales order numbers.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                CreateParcelItem(ShipmentHeader, Parcel, PurchaseLine, ShipmentMethodCode, ShippingAgentCode, ShippingAgentServiceCode, AccumulatedWeight);
            until PurchaseLine.Next() = 0;

        //Finally, we set the accumulated weight as the actual weight of our parcel. 
        Parcel.Validate("Actual Weight", AccumulatedWeight);
        Parcel.Modify(true);

        //This last line, selects and applies the best possible Sendcloud shipment method for the parcel we have created. 
        ShipmentAPI.TrySetBestShipmentMethod(Parcel);

        //Optionally here you could also call the following functions to directly post and print 
        //ShipmentAPI.Post(ShipmentHeader, false);
        //ShipmentAPI.Print(ShipmentHeader);

        ShowCreatedNotification();
    end;

    /// <summary>
    /// This function puts each item in the parcel. 
    /// </summary>
    /// <param name="ShipmentHeader"></param>
    /// <param name="Parcel"></param>
    /// <param name="PurchaseLine"></param>
    /// <param name="ShipmentMethodCode"></param>
    /// <param name="ShippingAgentCode"></param>
    /// <param name="ShippingAgentServiceCode"></param>
    /// <param name="AccumulatedWeight"></param>
    local procedure CreateParcelItem(var ShipmentHeader: Record "Shipment Header SCNVN"; var Parcel: Record "Parcel SCNVN"; var PurchaseLine: Record "Purchase Line"; ShipmentMethodCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10]; var AccumulatedWeight: Decimal)
    var
        Item: Record Item;
        ParcelItem: Record "Parcel Item SCNVN";
        SourceType: Enum "Parcel Source Type SCNVN";
    begin
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit;

        if not Item.Get(PurchaseLine."No.") then
            exit;

        //Here we create the parcel line per purchase line / per item.
        //We need to supply our Sendcloud shipment header and the parcel in which the item is placed. 
        //The 3rd parameter is the source record. Again the recordid will be stored just for reference. So here we use the purchase line.  
        //The following parameters identify which item/variant we are shipping, how many and what the weight is. 
        //Last we need to provide shipment method, agent, and service codes.
        ParcelItem := ShipmentAPI.CreateParcelItem(ShipmentHeader, Parcel, PurchaseLine, SourceType::Item, PurchaseLine."No.", '', PurchaseLine.Quantity, Item."Gross Weight", ShipmentMethodCode, ShippingAgentCode, ShippingAgentServiceCode);
        //The weight for this parcel item is added to the accumulated weight which can be used to set the actual weight on the parcel. 
        AccumulatedWeight += ParcelItem.Weight;
    end;

    /// <summary>
    /// This function is used to inform our user about what was created
    /// </summary>
    local procedure ShowCreatedNotification()
    var
        CreatedNotification: Notification;
        CreatedMsg: Label 'Sendcloud shipment has been created.';
    begin
        CreatedNotification.Message(CreatedMsg);
        CreatedNotification.Scope := NotificationScope::LocalScope;
        CreatedNotification.Send();
    end;

    /// <summary>
    /// This procedure initializes our codeunit by loading the setup record if needed
    /// </summary>
    local procedure Init()
    begin
        if not SetupLoaded then begin
            Setup.Get();
            SetupLoaded := true;
        end;
    end;

    var
        Setup: Record "Setup SCNVN";
        ShipmentAPI: Codeunit "Shipment API SCNVN";
        SetupLoaded: Boolean;
}
