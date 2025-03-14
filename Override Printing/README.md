# Override Label Printing
 
If you want to override printing for certain shipping labels, the you can use the OnBeforePrintLabel event. Printing is done based on a Parcel Response, which is the data object that is returned by the Sendcloud API. And in this example you will see how to retrieve the corresponding parcel, which you can then use to set the IsHandled parameter based on certain parcel, or related criteria. 
