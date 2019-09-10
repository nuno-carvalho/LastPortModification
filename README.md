# LastPortModification
Check when does a port switch (or other network device) change is port status

Based on SNMP queries, you can check when a port in a network device, change his status.

I wrote this, to check the Switch ports, unused a long time, a keep network racks clean.


10/sept/2019
Bug Fixes
- IP field size
- Clean states before rerun
- Properly work in devices up to 84 ports
- device hostname added to results
- Clean up code

ToDo:
- Test SNMP community/version
- make persistent values
