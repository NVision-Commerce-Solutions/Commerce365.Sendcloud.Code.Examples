codeunit 50002 "Parcel Events Demo 2 SCDNVN"
{
    /// <summary>
    /// If you have multiple parcels or orders to be delivered to the same receiver address, you can create a multicollo shipment to combine multiple boxes into one delivery. 
    /// Please first check with your desired carrier to see if they allow multicollo shipments. 
    /// Creating multicollo shipments through the Sendcloud API works by adjusting the Nr. of Labels field. 
    /// This way, upon posting, you are asking for more than one label for your parcel. And when printing you will get labels like label 1/3, 2/3 and 3/3. 
    /// To manage multicollo shipments programmatically you could use and event subscriber like demonstrated here. 
    /// Be aware that there are 2 OnAfterCreateParcel events. One is published when posting Sales Shipments and the other one when posting Sales Orders. 
    /// </summary>
    /// <param name="SalesShipmentHeader">Sales Shipment Header record (table 110)</param>
    /// <param name="ShipmentHeader">Sendcloud Shipment Header record (table 71312607)</param>
    /// <param name="Parcel">Sendcloud Parcel record (table 71312608)</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SSH Shipment Events SCNVN", 'OnAfterCreateParcel', '', false, false)]
    local procedure SSHShipmentEventsSCNVN_OnAfterCreateParcel(var SalesShipmentHeader: Record "Sales Shipment Header"; var ShipmentHeader: Record "Shipment Header SCNVN"; var Parcel: Record "Parcel SCNVN")
    var
        ShipmentAPISCNVN: Codeunit "Shipment API SCNVN";
    begin
        //Get the calculated weight value for our parcel
        Parcel.CalcFields(Weight);
        //Set the number of labels to a value higher than 1
        Parcel.Validate("No. of Labels", 25);
        //When requesting more than 1 label, you can set the actual weight to your desired weight per parcel
        Parcel.Validate("Actual Weight", (Parcel.Weight / Parcel."No. of Labels"));
        Parcel.Modify(true);
        //After the actual weight per parcel has been updated, you can run the TrySetBestShipmentMethod function again to determine the best possible shipment method. 
        //You might end up with a better/cheaper shipment method, because the weight per parcel might have been adjusted. 
        ShipmentAPISCNVN.TrySetBestShipmentMethod(Parcel);
    end;
}
