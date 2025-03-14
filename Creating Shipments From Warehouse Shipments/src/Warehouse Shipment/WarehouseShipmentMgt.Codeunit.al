codeunit 50003 "Create From Whse Shipt. SCDNVN"
{
    Access = Internal;
    TableNo = "Warehouse Shipment Header";
    Permissions = tabledata "Warehouse Shipment Line" = M;

    trigger OnRun()
    begin
        CreateShipment(Rec);
    end;

    /// <summary>
    /// This is the starting point for creating Sendcloud shipments based on a warehouse shipment document. 
    /// This function will gather all unique sales order numbers on the document, and then create a Sendcloud shipment for each sales order. 
    /// Bases on your preference you could also skip this step, and create one Sendcloud shipment for all lines on the document. 
    /// </summary>
    /// <param name="WarehouseShipmentHeader"></param>
    /// <returns></returns>
    internal procedure CreateShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"): Record "Shipment Header SCNVN";
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesOrderNos: List of [Code[20]];
        SalesOrderNo: Code[20];
        ShipmentsCreated: Integer;
    begin
        Init();

        //Get all sales order lines, and gather unique sales order numbers.
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        if WarehouseShipmentLine.FindSet() then
            repeat
                if not SalesOrderNos.Contains(WarehouseShipmentLine."Source No.") then
                    SalesOrderNos.Add(WarehouseShipmentLine."Source No.");
            until WarehouseShipmentLine.Next() = 0;

        //Per unique sales order number on our warehouse document we will create a Sendcloud shipment.
        foreach SalesOrderNo in SalesOrderNos do
            if CreateShipment(WarehouseShipmentHeader, SalesOrderNo) then
                ShipmentsCreated += 1;

        ShowCreatedNotification(ShipmentsCreated);
    end;

    /// <summary>
    /// This function creates the SC shipment per sales order number, but not neccesarily all lines on that sales order, because we are coming from a warehouse shipment document.
    /// Within this function we will create one parcel in which we will place all items / warehouse shipment lines.
    /// </summary>
    /// <param name="WarehouseShipmentHeader"></param>
    /// <param name="SalesOrderNo"></param>
    internal procedure CreateShipment(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesOrderNo: Code[20]): Boolean
    var
        SalesHeader: Record "Sales Header";
        ShipmentHeader: Record "Shipment Header SCNVN";
        Parcel: Record "Parcel SCNVN";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesDocumentType: Enum "Sales Document Type";
        AccumulatedWeight: Decimal;
    begin
        //Make sure we have our sales order and customer record.
        if not SalesHeader.Get(SalesDocumentType::Order, SalesOrderNo) then
            exit;

        //Create a Sendcloud Shipment Header for this sales order and its sell-to customer.
        //As the source we provide our warehouse shipment record. The recordid will be stored on our Sendcloud shipment just for reference. 
        ShipmentHeader := ShipmentAPI.CreateHeader(SalesHeader, 'DEMO123', WarehouseShipmentHeader);

        //Now that we have a header, we'll also add 1 parcel, based on the information from our sendcloud shipment header and sales header.
        Parcel := ShipmentAPI.CreateParcel(ShipmentHeader, SalesHeader);

        //As a last step we add all the lines from our warehouse document for this specific sales order.
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesOrderNo);
        if WarehouseShipmentLine.FindSet() then
            repeat
                CreateParcelItem(ShipmentHeader, Parcel, SalesHeader, WarehouseShipmentLine, AccumulatedWeight);
            until WarehouseShipmentLine.Next() = 0;

        //Finally, we set the accumulated weight as the actual weight of our parcel. 
        Parcel.Validate("Actual Weight", AccumulatedWeight);
        Parcel.Modify(true);

        //This last line, selects and applies the best possible Sendcloud shipment method for the parcel we have created. 
        ShipmentAPI.TrySetBestShipmentMethod(Parcel);

        //Optionally here you could also call the following functions to directly post and print 
        //ShipmentAPI.Post(ShipmentHeader, false);
        //ShipmentAPI.Print(ShipmentHeader);

        exit(true);
    end;

    /// <summary>
    /// This last function puts each item in the parcel. 
    /// </summary>
    /// <param name="SalesHeader"></param>
    /// <param name="WarehouseShipmentLine"></param>
    /// <param name="ShipmentHeader"></param>
    /// <param name="Parcel"></param>
    /// <param name="AccumulatedWeight"></param>
    local procedure CreateParcelItem(var ShipmentHeader: Record "Shipment Header SCNVN"; var Parcel: Record "Parcel SCNVN"; var SalesHeader: Record "Sales Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var AccumulatedWeight: Decimal)
    var
        Item: Record Item;
        ParcelItem: Record "Parcel Item SCNVN";
        SourceType: Enum "Parcel Source Type SCNVN";
    begin
        Item.Get(WarehouseShipmentLine."Item No.");
        if Item."Type" = Item."Type"::Service then
            exit;

        //Here we create the parcel line per warehouse shipment line / per item.
        //We need to supply our Sendcloud shipment header and the parcel in which the item is place. 
        //The 3rd parameter is the source record. Again the recordid will be stored just for reference. So here we use the warehouse shipment line. But, you could also bring the actual sales line along.
        //The following parameters identify which item/variant we are shipping, how many and what the weight is. 
        //Last we need to add shipment method, agent, and service codes to our line.
        ParcelItem := ShipmentAPI.CreateParcelItem(ShipmentHeader, Parcel, WarehouseShipmentLine, SourceType::Item, WarehouseShipmentLine."Item No.", '', WarehouseShipmentLine."Qty. to Ship", Item."Gross Weight", SalesHeader."Shipment Method Code", SalesHeader."Shipping Agent Code", SalesHeader."Shipping Agent Service Code");
        AccumulatedWeight += ParcelItem.Weight;
    end;

    /// <summary>
    /// This function is used to inform our user about what was created
    /// </summary>
    /// <param name="ShipmentCount">The number of shipments that have been created</param>
    local procedure ShowCreatedNotification(ShipmentCount: Integer)
    var
        CreatedNotification: Notification;
        CreatedMsg: Label '%1 Sendcloud shipment(s) have been created.', Comment = '%1=Shipment count';
    begin
        CreatedNotification.Message(StrSubstNo(CreatedMsg, ShipmentCount));
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
