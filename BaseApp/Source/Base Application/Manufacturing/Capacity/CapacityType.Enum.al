namespace Microsoft.Manufacturing.Capacity;

enum 5871 "Capacity Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Work Center") { Caption = 'Work Center'; }
    value(1; "Machine Center") { Caption = 'Machine Center'; }
}