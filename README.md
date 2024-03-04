The original data has a lot of issues and need to be cleaned to be usable.

Any incorrect value is replaced with NA.

The "projected invesement" column contains amounts described in different ways (millions, billions, different order of words). I unified the unit to million$ and converted everything into a numerical value.

The "status of deal" cloumn should only have 5 valid options, but there exist some incorrect ones and misspelled ones or alternative spelling.

I removed the unrealistic years.

Multiple placeholders are used for missing data (NA, "na", "---"). I unified them to all be NA.

Besides the types, there also exist multiple different names for the same country (US and United States; UK and United Kingdom). I unified them.

Two different names for the same sector (AB and agribusiness). I unified them.

Some entries contain vague descriptive comments. I removed the worst ones.

I also unified the cases so that the same keyword look exactly the same no matter where is appear in the list.

Plot 1 contains the info of projected investment each year, with country name indicated by color (I only used the entries in which none of these fields are missing).

There's one really tall spike in 2012, but the original data doesn't have anything suspicious. After reading the summary, I think it's legit.

Plot 2 contains the information of hectares of each year, with the status indicated by color.

Again, there's one extremely high value that looks like an outlier. But it matches the description, so it's also legit.

"GRAIN_RAW.xlsx" is the raw data with two data sheets.

I included two outputs: if I directly export as csv (data_processed.csv), in the "summary" column, it includes symbols that can't display properly in Excel. The second method (data_processed2.csv) fixes this.
