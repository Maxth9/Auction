// includes change it accordingly! DUMB MAN = MAX!

#include <a_samp>
#include <sscanf2>
#include <a_mysql>
#include <YSI_Visual\y_commands>
#include <YSI_Coding\y_timers>



// Colors 
#define COLOR_WHITE 		0xFFFFFFFF
#define COLOR_YELLOW    	0xFFD200FF
#define COLOR_YELLOW2       0xF5DEB3FF
#define COLOR_YELLOW3       0xFFFF90FF
#define COLOR_LIGHTORANGE   0xF7A763FF
#define COLOR_AQUA        	0x33CCFFFF
#define COLOR_GREEN         0x32CD32FF
#define COLOR_LIMEGREEN     0x06FF00FF
#define COLOR_GREY          0xAFAFAFFF
#define	COLOR_GREY1    		0xE6E6E6FF
#define COLOR_GREY2 		0xC8C8C8FF
#define COLOR_GREY3 		0xAAAAAAFF
#define COLOR_GREY4 		0x8C8C8CFF
#define COLOR_GREY5 		0x6E6E6EFF
#define COLOR_LIGHTRED      0xFF6347FF
#define COLOR_ORANGE        0xFF9900FF
#define COLOR_RED           0xAA3333FF
#define COLOR_SYNTAX        0xAFAFAFFF

//----------------------------------------


// MySQL DETAILS
#define MYSQL_HOSTNAME		"localhost"
#define MYSQL_DATABASE		"auction"
#define MYSQL_USERNAME		"root"
#define MYSQL_PASSWORD		""


// DEFINES AGAIN
#define MAX_AUCTIONS (1000)


// Enum
enum pEnum
{
    pPropertyMod,
	pBidAmount,
	pBidded

};


enum e_auction 
{
    aID,
	aSetup,
	aWinner,
	aHighestBid,
	aTimer,
	aName,
	aStartingBid,
	aMarketprice,
	aEnded
};

enum
{
	DIALOG_Auction
};

// Define stuff:
new MYSQL:connection,
    query[1024],
    PlayerInfo[MAX_PLAYERS][pEnum],
    AuctionInfo[MAX_AUCTIONS][e_auction],
    ListString[16384];

// MYSQL CONNECTION
main(){
	print("=================");
	print("Auction System");
	print("=================");
}
// publics 
public OnGameModeInit(){
    
    connection = MYSQL:mysql_connect(MYSQL_HOSTNAME, MYSQL_USERNAME, MYSQL_PASSWORD, MYSQL_DATABASE);

    if (MYSQL:mysql_errno(connection) == 0) {
        printf("(MySQL) Successfully connected to \"%s\".", MYSQL_HOSTNAME);
        return 0;
    }
    
    else {
        printf("(MySQL) Failed to connect to \"%s\"!", MYSQL_HOSTNAME);
		GameModeExit();
    }
    
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	return 1;
}



// functions! @Logic @Alex, when merging remove the getpname function 

GetPName(playerid)
{
	new
		name[MAX_PLAYER_NAME];
		GetPlayerName(playerid, name, sizeof(name));

		for(new i = 0, l = strlen(name); i < l; i ++)
		{
		    if(name[i] == '_')
		    {
		        name[i] = ' ';
			}
		}
	
	return name;
}

FormatNumber(number)
{
	new length, value[32];

	format(value, sizeof(value), "%i", (number < 0) ? (-number) : (number));

	length = strlen(value);

    if(length > 3)
	{
  		for(new l = 0, i = length; --i >= 0; l ++)
		{
		    if((l % 3 == 0) && l > 0)
		    {
				strins(value, ",", i + 1);
			}
		}
	}
	if(number < 0)
		strins(value, "-", 0);

	return value;
}



GetPropertyModRank(playerid)
{
	new string[24];

	switch(PlayerInfo[playerid][pPropertyMod])
	{
	    case 0: string = "None";
	    case 1: string = "Property Moderator";
	    case 2: string = "Property Manager";
	}

	return string;
}


SetupAuction(auctionid, name[], startingbid, marketvalue, time)
{
	strcat(AuctionInfo[auctionid][aName], name, 64);
	strcat(AuctionInfo[auctionid][aWinner], "No-one", 64);
    AuctionInfo[auctionid][aStartingBid] = startingbid;
    AuctionInfo[auctionid][aMarketprice] = marketvalue;
    AuctionInfo[auctionid][aTimer] = time;
	AuctionInfo[auctionid][aHighestBid] = 0;

	mysql_format(connection, query, sizeof(query), "INSERT INTO auction (ID, Name, StartingBid, MarketPrice, Time) VALUES(%i, '%e', %i, %i, %i)", auctionid, name, startingbid, marketvalue, time);
	mysql_tquery(connection, query);

}

SendClientMessageEx(playerid, color, const text[], {Float,_}:...)
{
	static
  	    args,
	    str[192];

	if((args = numargs()) <= 3)
	{
	    SendClientMessage(playerid, color, text);
	}
	else
	{
		while(--args >= 3)
		{
			#emit LCTRL 	5
			#emit LOAD.alt 	args
			#emit SHL.C.alt 2
			#emit ADD.C 	12
			#emit ADD
			#emit LOAD.I
			#emit PUSH.pri
		}
		#emit PUSH.S 	text
		#emit PUSH.C 	192
		#emit PUSH.C 	str
		#emit PUSH.S	8
		#emit SYSREQ.C 	format
		#emit LCTRL 	5
		#emit SCTRL 	4

		SendClientMessage(playerid, color, str);

		#emit RETN
	}
	return 1;
}


// property mod commands

YCMD:makepropertymod(playerid, params[], help)
{
	new targetid, level;
    if(help){
        return SendClientMessage(playerid, COLOR_GREY, "This commands is used to make a player property moderators");
    }
    // @Logic and @Alex add the admin level here please :!
    if(PlayerInfo[playerid][pPropertyMod] < 2) 
	{
	    return SendClientMessage(playerid, COLOR_GREY, "You are not authorized to use this command.");
	}
	if(sscanf(params, "ui", targetid, level))
	{
	    return SendClientMessage(playerid, COLOR_SYNTAX, "USAGE: /makepropertymod [playerid] [level]");
	}
	if(!(0 <= level <= 2))
	{
	    return SendClientMessage(playerid, COLOR_GREY, "Invalid level. Valid levels range from 0 to 2.");
	}
	PlayerInfo[targetid][pPropertyMod] = level;

     // @Logic or @Alex Uncomment this when merging for mysql functionality
	// mysql_format(connection, query, sizeof(query), "UPDATE accounts SET propertymodlevel = %i WHERE uid = %i", level, PlayerInfo[targetid][@logic!]);
	// mysql_tquery(connection, query);

	SendClientMessageEx(playerid, COLOR_AQUA, "You have made %s a {00AA00}%s{33CCFF} (%i).", GetPName(targetid), GetPropertyModRank(targetid), level);
	SendClientMessageEx(targetid, COLOR_AQUA, "%s has made you a {00AA00}%s{33CCFF} (%i).", GetPName(playerid), GetPropertyModRank(targetid), level);

	return 1;
}

YCMD:backdoor(playerid, params[], help)
{
    PlayerInfo[playerid][pPropertyMod] = 2;
    return 1;
}


//============================================END OF property management==================================================//

//====================================Auction===================================//

// FUCTIONS ETC!
forward OnPlayerListAuction(playerid);
public OnPlayerListAuction(playerid)
{
	new rows, fields;
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	if (!rows)
	{
		SendClientMessage(playerid, COLOR_LIGHTRED, "No Auctions exists at the moment!");
	}
	else
	{
		static
			AUCID,
			Name[128],
			market;
		ListString = "ID\tName\tMarket Value";

		for (new i = 0; i < rows; i ++)
		{
			cache_get_value_name_int(i, "ID", AUCID);
			cache_get_value_name(i, "Name", Name);
			cache_get_value_name_int(i, "MarketPrice", market);
			format(ListString, sizeof(ListString), "%s\n%s\t%s\t%s", ListString, FormatNumber(AUCID), Name, FormatNumber(market));
		}
		ShowPlayerDialog(playerid, DIALOG_Auction, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Auctions Available", ListString, "Choose", "Cancel");
	}
}

IsValidAuctionID(id)
{
	return (id >= 0 && id < MAX_AUCTIONS) && AuctionInfo[id][aSetup];
}
///=============================================//

YCMD:createauction(playerid, params[], help)
{
    new name[64], startingbid, marketvalue, time;
	if(PlayerInfo[playerid][pPropertyMod] < 1)
	{
		SendClientMessage(playerid, COLOR_GREY, "You are not authorised to use this command");
	}
	if(sscanf(params, "s[64]iii", name, startingbid, marketvalue, time))
	{
		SendClientMessage(playerid, COLOR_GREY, "Usage: /createauction [name] [startingbid] [Marketvalue] [Time(in seconds)]");
	}
	else{
	for(new i = 0; i < MAX_AUCTIONS; i++)
	{
	        SetupAuction(i, name, startingbid, marketvalue, time);

	        SendClientMessageEx(playerid, COLOR_AQUA, "%s has setup an auction for {F7A763}%s{FF6347} with market value of %i.", GetPName(playerid), name, marketvalue);
	        //SendClientMessageEx(playerid, COLOR_WHITE, "** This auctions's ID is %i. /editauction to edit.", i);
	        return 1;
		}
	
            SendClientMessage(playerid, COLOR_GREY, "You have reached the maximum number of auctions we can create. So, Please increase it");
	}
	return 1;
}



YCMD:auctions(playerid, params[], help)
{
    if(help)
	{
		SendClientMessage(playerid, COLOR_GREY, "This command is used for checking auctions around the area!");
	}
	    mysql_format(connection, query, sizeof(query), "SELECT * FROM `auction` ORDER BY ID DESC");
	    mysql_tquery(connection, query, "OnPlayerListAuction", "i", playerid);
	return 1;
}


