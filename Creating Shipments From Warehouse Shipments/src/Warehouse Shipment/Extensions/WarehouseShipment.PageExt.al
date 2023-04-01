pageextension 50250 "Warehouse Shipment SCDNVN" extends "Warehouse Shipment"
{
    actions
    {
        addlast(processing)
        {
            action("Create Shipment SCDNVN")
            {
                ApplicationArea = All;
                Caption = 'Create Sendcloud Shipment';
                Image = Shipment;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Codeunit "Create From Whse Shipt. SCDNVN";
                ToolTip = 'Creates one new Sendcloud shipment for all lines on this warehouse shipment.';
            }
        }
    }
}
