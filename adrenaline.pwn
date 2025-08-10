///////////////////////////////////////////////////////////////////////////////
//                    Adrenaline (Racing) - 2.0 - by Paige	                 //
///////////////////////////////////////////////////////////////////////////////
//                                 Credits: switch                           //
//                                                                           //
//                                 Coding:                                   //
//                                                                           //
//                 Kynen: Highscore() code he made for me                    //
//          Y_Less: Used GetXYInFrontOfPlayer() as base of Grid function     //
//        Simon: Used ConvertToSafeInput() as base for CheckSafeInput()      //
//                            Dabombber: TimeConvert()                       //
//             Yagu: Referenced his race filterscript early on               //
//             http://forum.sa-mp.com/index.php?topic=20637.0                //
//                                                                           //
//                                                                           //
//                                 Testing:                                  //
//                                                                           //
//                               aerodynamics                                //
//                                [RSD]Potti                                 //
//         any other person who crashed while on my TestServer :)            //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

#include <open.mp>
#define TIME_PULL_MONEY 16384
#define TIME_GIVE_CAR 3000
#define TIME_MOVE_PLAYER 4000
#define TIME_PUT_PLAYER 3000
#define TIME_SHOW_VOTE 4000
#define TIME_TO_FINISH_MENU 512
#define CARS_NUMBER 4

#define SPARE_CARS 2 //number of spare cars per race
#define RACES_TILL_MODECHANGE 0 //for use if you just want a few races to play then change to another mode
#define SHOW_JOINS_PARTS //comment out if you don't want hide/parts shown
#define CHECK_SIZE 12.0 //checkpoint size
#define COLOR_TEMP 0xFFFFFFAA

#define MAX_RACES 200
#define MAX_RACECHECKPOINTS 100

#define dcmd(%1,%2,%3) if ((strcmp((%3)[1], #%1, true, (%2)) == 0) && ((((%3)[(%2) + 1] == 0) && (dcmd_%1(playerid, "")))||(((%3)[(%2) + 1] == 32) && (dcmd_%1(playerid, (%3)[(%2) + 2]))))) return 1  //CREDIT: DracoBlue

// REGISTRATION
#define DIALOG_LOGIN     1000
#define DIALOG_REGISTER  1001

enum E_PLAYER_DATA {
    pLoggedIn,
    pPassword[32],
    pXP,
    pRank,
    pWins,
    pMoney,
    pSkin,
    pReady,
	pIngame,
    pBoughtCarsHealth[CARS_NUMBER],
    pRentedCarRaces[CARS_NUMBER],
    pBoughtCarColor[CARS_NUMBER],
    pRentedCarColor[CARS_NUMBER],
    pCurrentCar,
    pCurrentRent
};
new gPlayerData[MAX_PLAYERS][E_PLAYER_DATA];

// rank hud
new Text:TRankHUD[MAX_PLAYERS];
new Text:TXP[MAX_PLAYERS];
//

new gMaxCheckpoints;
new Float:RaceCheckpoints[MAX_RACECHECKPOINTS][4];
new Float:xRaceCheckpoints[MAX_PLAYERS][MAX_RACECHECKPOINTS][4];
new xWorldTime[MAX_PLAYERS];
new xTrackTime[MAX_PLAYERS];
new xWeatherID[MAX_PLAYERS];
new xRaceType[MAX_PLAYERS];
new xRaceName[MAX_PLAYERS][256];
new playerCreatedVehicle[MAX_PLAYERS];
new Float:xFacing[MAX_PLAYERS];
new xCreatorName[MAX_PLAYERS][MAX_PLAYER_NAME];
new xRaceBuilding[MAX_PLAYERS];
new xCarIds[MAX_PLAYERS][5];
new gPlayerProgress[MAX_PLAYERS];
new xPlayerProgress[MAX_PLAYERS];
new gFinishOrder;
new gRaceNames[MAX_RACES][128];
new gRaceStart;
new gCountdown;
new gRaceStarted;
new gWorldTime;
new gWeather;
new gCountdowntimer;
new gEndRacetimer;
new finishInCarTimer[MAX_PLAYERS];
new gTrackTime;
new Float:gGrid[8];
new Float:gGrid2[8];
new vehicles[MAX_PLAYERS];
new gRaces;
new Menu:voteMenu;
new Menu:carShopMenu;
new Menu:garageMenu;
new Menu:buyCarMenu[MAX_PLAYERS];
new Menu:rentCarMenu[MAX_PLAYERS];
new Menu:repairMenu[MAX_PLAYERS];
new Menu:carColorMenu[MAX_PLAYERS];
new Menu:rentCarRacesMenu[MAX_PLAYERS];
new Menu:buildMenu[MAX_PLAYERS];
new inGarageMenu[MAX_PLAYERS];
new inCarsMenu[MAX_PLAYERS];
new inCarsMenuFinished[MAX_PLAYERS];
new carTypeSelection[MAX_PLAYERS];
new rentRacesSelection[MAX_PLAYERS];
new carCost[1024];
new carName[1024][256];
new gVoteItems[4][256];
new gVotes[4];
new gRacePosition[MAX_PLAYERS];
new gTotalRacers;
new gTrackName[256];
new gGridIndex;
new gGridCount;
new gGrid2Index;
new gGrid2Count;
new gCarModelID;
new gRaceType;
new gRaceMaker[256];
new gFinished;
new spawned[MAX_PLAYERS];
new postLoginInited[MAX_PLAYERS];
new newcar[MAX_PLAYERS];
new gWorldID;

new showVoteTimer[MAX_PLAYERS];
new gNextTrack[256];
new gVehDestroyTracker[700];
new gGiveCarTimer[MAX_PLAYERS];
new pullMoneyTimer[MAX_PLAYERS];
new gScores[MAX_PLAYERS][2];
new gScores2[MAX_PLAYERS][2];
new gGrided[MAX_PLAYERS];
new racecount;
new gTrackTimeSaved = 0;
new invalidateResult = 0;


new Text:Ttime;
new Text:Ttotalracers;
new Text:Tposition[MAX_PLAYERS];
new Text:Tappend[MAX_PLAYERS];
new gMinutes, gSeconds;
new gindex;
new casinoInPickup;
new casinoOutPickup;
new carShopPickup;
new garagePickup;
#define MAX_RANKS 11

new const RankNames[MAX_RANKS][] = {
    "Rookie",
    "Street Rider",
    "Tuner",
    "Drift Kid",
    "Highway Hunter",
    "Turbo Outlaw",
    "Race King",
    "JDM Legend",
    "Midnight Master",
    "Fast & Furious",
    "The Boss"
};

new const shopCarIds[CARS_NUMBER] = {
    551,
    521,
    500,
    581
};

new const shopCarNames[CARS_NUMBER][256] = {
    "Merit",
    "FCR-900",
    "Mesa",
    "BF-400"
};


// cost = https://www.gtabase.com/gta-san-andreas/vehicles/ cost / 40
new const shopCarCost[CARS_NUMBER] = {
    875,
    1250, // x 10
    625,
    250
};

new const RankXP[MAX_RANKS] = {
    0,     // Rookie
    50,
    150,
    300,
    600,
    1000,
    1600,
    2300,
    3200,
    4500,
    6000
};

new const RankColors[MAX_RANKS] = {
    0xAAAAAAFF, // Rookie - Серый
    0xFFFFFFAA, // Street Rider - Белый
    0x55DDFFFF, // Tuner - Голубой
    0x0070FFFF, // Drift Kid - Синий
    0xFFFF00FF, // Highway Hunter - Жёлтый
    0xFFA500FF, // Turbo Outlaw - Оранжевый
    0xFF0000FF, // Race King - Красный
    0xBB00BBFF, // JDM Legend - Малиновый
    0x8A2BE2FF, // Midnight Master - Фиолетовый
    0x000000FF, // Fast & Furious - Чёрный
    0xFFD700FF  // The Boss - Золотой
};

#define HIGH_SCORE_SIZE 5                   //Max number of ppl on the highscore list

enum rStats {                                               //Highscore enum
     rName[128],
     rTime,
     rRacer[MAX_PLAYER_NAME],
};
new gBestTime[256];



forward Countdowntimer();
forward nextRaceCountdown();
forward countVotes();
forward changetrack();
forward showVote(playerid);
forward RemovePlayersFromVehicles();
forward DestroyAllVehicles();
forward destroyCarSafe(veh);
forward giveCar(playerid, modelid, world);
forward GridSetup(playerid);
forward GridSetupPlayer(playerid);
forward PutPlayerInVehicleTimed(playerid, veh, slot);
forward respawnCar(veh);
forward updateTime();
forward AddRacers(num);
forward RespawnPlayer(playerid);
forward HideXPText(playerid);


//////////////////////////////////////////////////
//// x.x SA-MP FUNCTIONS (START) /////////////////
//////////////////////////////////////////////////

public OnPlayerSelectedMenuRow(playerid, row)
{
/*	if (row==0)
	{
	    SetTimerEx("showVotes",800,0,"d",playerid);
		return 0;
	}*/
	new Menu:Current = GetPlayerMenu(playerid);
	if (Current == voteMenu)
	{
		new vmsg[256],pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		format(vmsg,256,"* %s проголосовал за %s",pname,gVoteItems[row]);
		SendClientMessageToAll(COLOR_TEMP,vmsg);
		gVotes[row]++;
		TogglePlayerControllable(playerid,1);
		return 1;
	} else if (Current == carShopMenu) {
        new c = gPlayerData[playerid][pCurrentCar];
        switch (row) {
            case 0: {
	            DestroyMenu(buyCarMenu[playerid]);
	            buyCarMenu[playerid] = CreateMenu("Buy Car",2, 50.0, 200.0, 120.0, 250.0);
	            for (new i = 0; i < CARS_NUMBER; ++i) {
                    AddMenuItem(buyCarMenu[playerid],0,FormatCarPurchase(shopCarNames[i], i, playerid, c));
                    new cmsg[256];
                    format(cmsg, 256, "$%d", shopCarCost[i]);
                    AddMenuItem(buyCarMenu[playerid],1,cmsg);
	            }
                ShowMenuForPlayer(buyCarMenu[playerid],playerid);
            }
            case 1: {
	            DestroyMenu(rentCarMenu[playerid]);
	            rentCarMenu[playerid] = CreateMenu("Rent Car",1, 50.0, 200.0, 220.0, 250.0);
	            for (new i = 0; i < CARS_NUMBER; ++i) {
                    AddMenuItem(rentCarMenu[playerid],0,FormatCarRent(shopCarNames[i], i, playerid, c));
                }
                ShowMenuForPlayer(rentCarMenu[playerid],playerid);
            }
        }
		return 1;
    } else if (Current == garageMenu) {
        new c = gPlayerData[playerid][pCurrentCar];
        switch (row) {
            case 0: {
                DestroyMenu(buyCarMenu[playerid]);
                buyCarMenu[playerid] = CreateMenu("Choose a Car",1, 50.0, 200.0, 320.0, 250.0);
	            for (new i = 0; i < CARS_NUMBER; ++i) {
                    AddMenuItem(buyCarMenu[playerid],0,FormatCarPurchase(shopCarNames[i], i, playerid, c));
                }
                ShowMenuForPlayer(buyCarMenu[playerid],playerid);
            }
            case 1: {
	            DestroyMenu(rentCarMenu[playerid]);
	            rentCarMenu[playerid] = CreateMenu("Choose a Car",1, 50.0, 200.0, 220.0, 250.0);
	            for (new i = 0; i < CARS_NUMBER; ++i) {
                    AddMenuItem(rentCarMenu[playerid],0,FormatCarRent(shopCarNames[i], i, playerid, c));
                }
                ShowMenuForPlayer(rentCarMenu[playerid],playerid);
            }
            case 2: {
	            DestroyMenu(repairMenu[playerid]);
	            repairMenu[playerid] = CreateMenu("Repair Car",2, 50.0, 200.0, 120.0, 250.0);
	            for (new i = 0; i < CARS_NUMBER; ++i) {
                    AddMenuItem(repairMenu[playerid],0,FormatCarPurchase(shopCarNames[i], i, playerid, c));
                    new cmsg[256];
                    format(cmsg, 256, "$%d", carCost[shopCarIds[i]] / 10);
                }
                ShowMenuForPlayer(repairMenu[playerid],playerid);
            }
        }
		return 1;
    } else if (Current == buyCarMenu[playerid]) {
        if (inGarageMenu[playerid] == 1) {
            if (gPlayerData[playerid][pBoughtCarsHealth][row] < 25) {
                SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] машина не куплена или сломана");
            } else {
                gPlayerData[playerid][pCurrentCar] = row;
                gPlayerData[playerid][pCurrentRent] = 0;
            }
            TogglePlayerControllable(playerid,1);
            inCarsMenu[playerid] = 0;
            inCarsMenuFinished[playerid] = 1;
        } else {
            if (gPlayerData[playerid][pMoney] < carCost[shopCarIds[row]]) {
                SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] недостаточно денег");
                TogglePlayerControllable(playerid,1);
                inCarsMenu[playerid] = 0;
                inCarsMenuFinished[playerid] = 1;
            } else if (gPlayerData[playerid][pBoughtCarsHealth][row] > 0) {
                SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] уже куплено");
                TogglePlayerControllable(playerid,1);
                inCarsMenu[playerid] = 0;
                inCarsMenuFinished[playerid] = 1;
            } else {
                carTypeSelection[playerid] = row;
                rentRacesSelection[playerid] = 0;
                
                ColorMenu(playerid);
            }
        }
		return 1;
    } else if (Current == rentCarMenu[playerid]) {
        if (inGarageMenu[playerid] == 1) {
            if (gPlayerData[playerid][pRentedCarRaces][row] == 0) {
                SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] машина не арендована");
            } else {
                gPlayerData[playerid][pCurrentCar] = row;
                gPlayerData[playerid][pCurrentRent] = 1;
            }
            TogglePlayerControllable(playerid,1);
            inCarsMenu[playerid] = 0;
            inCarsMenuFinished[playerid] = 1;
        } else {
            carTypeSelection[playerid] = row;
            
            new cmsg[256];
            format(cmsg,256,"Rent %s", carName[shopCarIds[carTypeSelection[playerid]]]);
            DestroyMenu(rentCarRacesMenu[playerid]);
            rentCarRacesMenu[playerid] = CreateMenu(cmsg,2, 50.0, 200.0, 120.0, 250.0);
            SetMenuColumnHeader(rentCarRacesMenu[playerid],0,"Races");
            AddMenuItem(rentCarRacesMenu[playerid],0,"1");
            AddMenuItem(rentCarRacesMenu[playerid],0,"2");
            AddMenuItem(rentCarRacesMenu[playerid],0,"5");
            AddMenuItem(rentCarRacesMenu[playerid],0,"10");
            SetMenuColumnHeader(rentCarRacesMenu[playerid],1,"Cost");
            new cost = carCost[shopCarIds[carTypeSelection[playerid]]];
            format(cmsg, 256, "$%d", cost / 10);
            AddMenuItem(rentCarRacesMenu[playerid],1, cmsg);
            format(cmsg, 256, "$%d", cost * 8 / 70);
            AddMenuItem(rentCarRacesMenu[playerid],1, cmsg);
            format(cmsg, 256, "$%d", cost * 2 / 5);
            AddMenuItem(rentCarRacesMenu[playerid],1, cmsg);
            format(cmsg, 256, "$%d", cost * 7 / 10);
            AddMenuItem(rentCarRacesMenu[playerid],1, cmsg);
            ShowMenuForPlayer(rentCarRacesMenu[playerid],playerid);
            return 1;
        }
    } else if (Current == repairMenu[playerid]) {
        if (gPlayerData[playerid][pBoughtCarsHealth][row] == 0) {
            SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] машина не куплена");
        } else {
	        new cost = carCost[shopCarIds[row]] / 10;
		    gPlayerData[playerid][pMoney] -= cost;
		    GivePlayerMoney(playerid,-cost);
    	    gPlayerData[playerid][pBoughtCarsHealth][row] = 100;
        }
        TogglePlayerControllable(playerid,1);
        inCarsMenu[playerid] = 0;
        inCarsMenuFinished[playerid] = 1;
    } else if (Current == carColorMenu[playerid]) {
	    new cost = carCost[shopCarIds[carTypeSelection[playerid]]];
        if (rentRacesSelection[playerid] == 0) {
    	    gPlayerData[playerid][pBoughtCarsHealth][carTypeSelection[playerid]] = 100;
    	    gPlayerData[playerid][pBoughtCarColor][carTypeSelection[playerid]] = colorFromRow(row);
    	} else {
    	    new races;
    	    new rowRaces = rentRacesSelection[playerid] - 1;
            switch (rowRaces) {
                case 0: {
                    cost /= 10;
                    races = 1;
                }
                case 1: {
                    cost = cost * 8 / 70;
                    races = 2;
                }
                case 2: {
                    cost = cost * 2 / 5;
                    races = 5;
                }
                case 3: {
                    cost = cost * 7 / 10;
                    races = 10;
                }
            }
    	    gPlayerData[playerid][pRentedCarRaces][carTypeSelection[playerid]] += races;
    	    gPlayerData[playerid][pRentedCarColor][carTypeSelection[playerid]] = colorFromRow(row);
    	}
		gPlayerData[playerid][pMoney] -= cost;
		GivePlayerMoney(playerid,-cost);
		TogglePlayerControllable(playerid,1);
		inCarsMenu[playerid] = 0;
		inCarsMenuFinished[playerid] = 1;
		return 1;
    } else if (Current == rentCarRacesMenu[playerid]) {
        rentRacesSelection[playerid] = row + 1;
        new cost = carCost[shopCarIds[carTypeSelection[playerid]]];
        switch (row) {
            case 0: cost /= 10;
            case 1: cost = cost * 8 / 70;
            case 2: cost = cost * 2 / 5;
            case 3: cost = cost * 7 / 10;
        }
        if (gPlayerData[playerid][pMoney] < cost) {        
    		SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] недостаточно денег");
		    TogglePlayerControllable(playerid,1);
		    inCarsMenu[playerid] = 0;
		    inCarsMenuFinished[playerid] = 1;
        } else {
            ColorMenu(playerid);
        }
		return 1;
    } else if (Current == buildMenu[xRaceBuilding[playerid]-1])
	{
	    print("Делает что-то в билдменю");
	    switch (xRaceBuilding[playerid])
	    {

		    case 1:
		    {
				switch (row)
				{
				    case 0: xWorldTime[playerid] = 0;
				    case 1: xWorldTime[playerid] = 3;
				    case 2: xWorldTime[playerid] = 6;
				    case 3: xWorldTime[playerid] = 9;
				    case 4: xWorldTime[playerid] = 12;
				    case 5: xWorldTime[playerid] = 15;
				    case 6: xWorldTime[playerid] = 18;
				    case 7: xWorldTime[playerid] = 21;
				}
		    }
		    case 2:
		    {
				switch (row)
				{
				    case 0: xWeatherID[playerid] = 0;
				    case 1: xWeatherID[playerid] = 10;
				    case 2: xWeatherID[playerid] = 12;
				    case 3: xWeatherID[playerid] = 16;
				    case 4: xWeatherID[playerid] = 16;
				    case 5: xWeatherID[playerid] = 19;
				}
		    }
		    case 3:
		    {
				switch (row)
				{
				    case 0: xTrackTime[playerid] = 60;
				    case 1: xTrackTime[playerid] = 120;
				    case 2: xTrackTime[playerid] = 180;
				    case 3: xTrackTime[playerid] = 240;
				    case 4: xTrackTime[playerid] = 300;
				    case 5: xTrackTime[playerid] = 360;
				    case 6: xTrackTime[playerid] = 480;
				    case 7: xTrackTime[playerid] = 600;
				    case 8: xTrackTime[playerid] = 900;
				}
		    }

		    case 4:
		    {
				switch (row)
				{
				    case 0: xRaceType[playerid] = 1;
				    case 1: xRaceType[playerid] = 2;
				}
		    }
		    case 5:
		    {
				switch (row)
				{
				    case 0: xCarIds[playerid][0] = 451;
				    case 1: xCarIds[playerid][0] = 565;
				    case 2: xCarIds[playerid][0] = 429;
				    case 3: xCarIds[playerid][0] = 415;
				    case 4: xCarIds[playerid][0] = 558;
				    case 5: xCarIds[playerid][0] = 522;
				    case 6: xCarIds[playerid][0] = 468;
				    case 7: xCarIds[playerid][0] = 513;
				    case 8: xCarIds[playerid][0] = 452;
				    case 9: xCarIds[playerid][0] = 0, print("More..");
				}
				if (xCarIds[playerid][0] > 0)
				{
				    SetPlayerVirtualWorld(playerid, playerid+100);
				    printf("playerVirtual: %d world:%d",playerid, playerid+100);
					newCar(playerid);
				}
		    }
		    case 6:
		    {
				switch (row)
				{
				    case 0: xCarIds[playerid][0] = 560;
				    case 1: xCarIds[playerid][0] = 506;
				    case 2: xCarIds[playerid][0] = 567;
				    case 3: xCarIds[playerid][0] = 424;
				    case 4: xCarIds[playerid][0] = 556;
				    case 5: xCarIds[playerid][0] = 541;
				    case 6: xCarIds[playerid][0] = 494;
				    case 7: xCarIds[playerid][0] = 571;
				    case 8: xCarIds[playerid][0] = 520;
				    case 9: xCarIds[playerid][0] = 0, print("More..");
				}
				if (xCarIds[playerid][0] > 0)
				{
				    SetPlayerVirtualWorld(playerid, playerid+100);
				    printf("playerVirtual: %d world:%d",playerid, playerid+100);
					newCar(playerid);
				}
		    }
		}
	    
	    printf("DEBUG: xCarIds=%d xracebuilding=%d",xCarIds[playerid][0],xRaceBuilding[playerid]);
	    //HideMenuForPlayer(buildMenu[xRaceBuilding[playerid]-1],playerid);
		xRaceBuilding[playerid]++;
		printf("xRaceBuilding=%d",xRaceBuilding[playerid]);
		if (xCarIds[playerid][0]==0)
		{
		    switch (xRaceBuilding[playerid])
		    {
				case 7:
				{
				    xRaceBuilding[playerid]=xRaceBuilding[playerid]-2;
					ShowMenuForPlayer(buildMenu[xRaceBuilding[playerid]-1],playerid);
				}
		        default:
				{
					ShowMenuForPlayer(buildMenu[xRaceBuilding[playerid]-1],playerid);
				}
		    }
			
			print("Got here");
		}
		else {
		    SendClientMessage(playerid, COLOR_TEMP, "Задай название трассы! Eg /set RaceDemon");
			printf("SER RACE NAME; racebuilding %d; pworld:%d",xRaceBuilding[playerid], playerid+100);

		}
		return 1;
	}
	return 1;
}

colorFromRow(row) {
    if (row == 4)
        return -1;
    return row;
}

ColorMenu(playerid) {
    new cmsg[256];
    format(cmsg,256,"Color of %s", carName[carTypeSelection[playerid]]);
    
    DestroyMenu(carColorMenu[playerid]);
    carColorMenu[playerid] = CreateMenu(cmsg,2, 50.0, 200.0, 120.0, 250.0);
    AddMenuItem(carColorMenu[playerid],0,"Black");
    AddMenuItem(carColorMenu[playerid],0,"White");
    AddMenuItem(carColorMenu[playerid],0,"Blue");
    AddMenuItem(carColorMenu[playerid],0,"Red");
    AddMenuItem(carColorMenu[playerid],0,"Random");
    ShowMenuForPlayer(carColorMenu[playerid],playerid);
}

FormatCarPurchase(name[], row, playerid, c) {
    new fmsg[256];
    format(fmsg,256,"(%d/100)",gPlayerData[playerid][pBoughtCarsHealth][row]);
    new cmsg[256];
    format(cmsg,256,"%s%s%s", c == row && gPlayerData[playerid][pCurrentRent] == 0 ? "#" : "", name, gPlayerData[playerid][pBoughtCarsHealth][row] > 0 ? fmsg : "");
    return cmsg;
}

FormatCarRent(name[], row, playerid, c) {
    new cmsg[256];
    format(cmsg,256,"%s%s(%d)", c == row && gPlayerData[playerid][pCurrentRent] == 1 ? "#" : "", name, gPlayerData[playerid][pRentedCarRaces][row]);
    return cmsg;
}

public OnGameModeInit()
{
	SetGameModeText("Adrenaline (Racing)");
	AddPlayerClass(170,1522.2528,-887.0850,61.1224,248.4600,0,0,0,0,0,0); //

    casinoInPickup = CreatePickup(19198, 23, 59.3707,3413.6506,5.5705);
    casinoOutPickup = CreatePickup(19198, 23, 2233.67798, 1714.32825, 1012.39697);
	LoadRaceList(); 		//Opens up racenames.txt and reads off the racenames to be used
	LoadRace(gRaceNames[random(gRaces)]); 		//The first race is picked at random and loaded
	createTextDraws();		//Creates all the TextDraws for time, position
	createBuildMenus();     //Creates the menus for building races
	SetTimer("updateTime",1000,1);      //Sets a timer going to update the TextDraw for the displayed racetime
	for (new i=0;i<MAX_PLAYERS;i++)	gScores[i][0]=i;
    
	DisableInteriorEnterExits();

    CreateCarShop();
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
    if(pickupid == casinoInPickup)
    {
        SetPlayerInterior(playerid,1);
	    SetPlayerPos(playerid, 2233.8032, 1712.2303, 1011.7632);
    }
    else if(pickupid == casinoOutPickup)
    {
        SetPlayerInterior(playerid,0);
	    SetPlayerPos(playerid, 59.3028, 3418.3611, 4.7159);
    } 
    else if(pickupid == carShopPickup)
    {
        if (inCarsMenu[playerid] == 0) {
            if (inCarsMenuFinished[playerid] == 0) {
                shop(playerid);
            } else {
                KillTimer(finishInCarTimer[playerid]);
                finishInCarTimer[playerid] = SetTimerEx("FinishInCarsMenu", TIME_TO_FINISH_MENU, 0, "d", playerid);
            }
        }
    }
    else if(pickupid == garagePickup)
    {
        if (inCarsMenu[playerid] == 0) {
            if (inCarsMenuFinished[playerid] == 0) {
                garage(playerid);
            } else {
                KillTimer(finishInCarTimer[playerid]);
                finishInCarTimer[playerid] = SetTimerEx("FinishInCarsMenu", TIME_TO_FINISH_MENU, 0, "d", playerid);
            }
        }
    }
    return 1;
}

public FinishInCarsMenu(playerid) {
    inCarsMenuFinished[playerid] = 0;
}

public OnPlayerText(playerid, text[])
{
    new rank = gPlayerData[playerid][pRank];
    new color = RankColors[rank];

    new pname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, pname, sizeof(pname));

    new msg[144];
    format(msg, sizeof(msg), "{%06x}[%s]{FFFFFF} %s: %s", (color >>> 8), RankNames[rank], pname, text);

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i))
        {
            SendClientMessage(i, -1, msg);
        }
    }

    return 0; // блокируем стандартный вывод
}

public OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys)
{
	if(IsKeyJustDown(KEY_FIRE,newkeys,oldkeys) && xRaceBuilding[playerid]>=1)//Has the player just pressed mouse1 when they are in buildmode?
	{
	    if(xPlayerProgress[playerid]==MAX_RACECHECKPOINTS)
	    {
	    		SendClientMessage(playerid,COLOR_TEMP,"Максимальное количество чекпойнтов достигнуто!");
	    		return;
	    }
		GetPlayerPos(playerid, xRaceCheckpoints[playerid][xPlayerProgress[playerid]][0],xRaceCheckpoints[playerid][xPlayerProgress[playerid]][1],xRaceCheckpoints[playerid][xPlayerProgress[playerid]][2]);
		SetPlayerRaceCheckpoint(playerid, 2, xRaceCheckpoints[playerid][xPlayerProgress[playerid]][0],xRaceCheckpoints[playerid][xPlayerProgress[playerid]][1],xRaceCheckpoints[playerid][xPlayerProgress[playerid]][2], xRaceCheckpoints[playerid][xPlayerProgress[playerid]][0],xRaceCheckpoints[playerid][xPlayerProgress[playerid]][1],xRaceCheckpoints[playerid][xPlayerProgress[playerid]][2],CHECK_SIZE);
	    switch (xPlayerProgress[playerid])
	    {
	        case 0:
	        {
				SendClientMessage(playerid,COLOR_TEMP,"[INFO] Начальная точка 1 задана! Теперь используй FIRE чтобы задать стартовую точку для игрока 2 (2nd Grid position)");
				new veh = GetPlayerVehicleID(playerid);
				GetVehicleZAngle(veh, xFacing[playerid]);
	        }
	        case 1:
	        {
	        	SendClientMessage(playerid,COLOR_TEMP,"[INFO] Начальная точка 2 задана! Теперь используй FIRE чтобы задать гоночный чекпойнт. Напиши /saverace когда закончишь!");
	        }
	        default:
	        {
	            new msg[256];
	            format(msg,256,"[INFO] Чекпойнт %d задан! Напиши /saverace когда закончишь",xPlayerProgress[playerid]-2);
				SendClientMessage(playerid,COLOR_TEMP,msg);
			}
		}
		xPlayerProgress[playerid]++;
		PlaySoundForPlayer(playerid, 1137);
		return;
	}
}

public OnGameModeExit()
{
	return 1;
}


public OnPlayerRequestClass(playerid, classid)
{
    return 0;
}



public OnPlayerSpawn(playerid)
{
    printf("[DEBUG] OnPlayerSpawn: playerid=%d", playerid);
    spawned[playerid] = 1;
    
#if defined SHOW_JOINS_PARTS
    if (postLoginInited[playerid] == 0) {
        new pname[MAX_PLAYER_NAME], pmsg[256];
        GetPlayerName(playerid, pname, sizeof(pname));

        new rank = gPlayerData[playerid][pRank];
        new color = RankColors[rank];

        format(pmsg, sizeof(pmsg), "*** {%06x}[%s]{FFFFFF} %s зашёл на сервер", (color >>> 8), RankNames[rank], pname);
        SendClientMessageToAll(COLOR_TEMP, pmsg);
        pullMoneyTimer[playerid] = SetTimerEx("PullMoney", TIME_PULL_MONEY, 1, "d", playerid);
        postLoginInited[playerid] = 1;
    }
#endif

    if (!gPlayerData[playerid][pReady])
    {
        SendClientMessage(playerid, -1, "{00DDDD}[ИНФО]{FFFFFF} Вы не готовы к гонке. Используйте команду {00FF00}/ready{FFFFFF}, чтобы присоединиться к следующей гонке.");
        return 1; // Не запускаем гонку
    }

    // Гонка уже идёт — можно добросить на трассу
    if (gTrackTime > 10)
    {
        GridSetupPlayer(playerid);
        SetTimerEx("GridSetup", TIME_GIVE_CAR, 0, "d", playerid);
    }
    else
    {
        SendClientMessage(playerid, COLOR_TEMP, "Track is changing, please wait...");
    }

    PlaySoundForPlayer(playerid, 1186);

    return 1;
}


public OnPlayerEnterRaceCheckpoint(playerid)
{
	if (xRaceBuilding[playerid]>=1) return 1;
	new State = GetPlayerState(playerid);
	if(State != PLAYER_STATE_DRIVER) //Players need to be in a car and be the driver to progress to the next cp
	{
	    return 1;
	}
	
	if(gPlayerData[playerid][pCurrentRent]==0) {
	    new Float:health;
	    GetVehicleHealth(playerCreatedVehicle[playerid], health);
	    gPlayerData[playerid][pBoughtCarsHealth][gPlayerData[playerid][pCurrentCar]] = floatround(health / 10);
	}

	if (gPlayerProgress[playerid]==gMaxCheckpoints-1) //If the player has finished...
	{
		gFinished++;

		if (gFinished == gTotalRacers && gTrackTime>35) gTrackTime=35;
	    new finishmsg[256],pname[MAX_PLAYER_NAME],append[3];
		GetPlayerName(playerid,pname,MAX_PLAYER_NAME);

		new Time, timestamp;
		timestamp = GetTickCount();
		Time = timestamp - gRaceStart;

		new Minutes, Seconds, MSeconds, sMSeconds[5],sSeconds[5];
		timeconvert(Time, Minutes, Seconds, MSeconds);

		if (Seconds < 10)format(sSeconds, sizeof(sSeconds), "0%d", Seconds);
		else format(sSeconds, sizeof(sSeconds), "%d", Seconds);
		if (MSeconds < 100)format(sMSeconds, sizeof(sMSeconds), "0%d", MSeconds);
		else format(sMSeconds, sizeof(sMSeconds), "%d", MSeconds);


	    gFinishOrder++;
		switch (gFinishOrder)
		{
			case 1,21,31,41,51,61,71,81,91:	format(append, sizeof(append), "st");
			case 2,22,32,42,52,62,72,82,92:	format(append, sizeof(append), "nd");
			case 3,23,33,43,53,63,73,83,93: format(append, sizeof(append), "rd");
			default: format(append, sizeof(append), "th");
		}
		new prize;
		switch (gFinishOrder)
		{
			case 1: prize=10;
			case 2:	prize=8;
			case 3:	prize=6;
			case 4:	prize=4;
			case 5:	prize=3;
  			case 6:	prize=2;
			default: prize=1;
		}
		SetPlayerScore(playerid, GetPlayerScore(playerid)+prize);
		gScores[playerid][1]+=prize;
		
		// rank add XP
		new xpReward = CalculateXPReward(gTotalRacers, min(gFinishOrder, gTotalRacers));
		gPlayerData[playerid][pXP] += xpReward;
		ShowXPText(playerid, xpReward);
	        
		// rank add money
		new moneyReward = CalculateMoneyReward(gTotalRacers, min(gFinishOrder, gTotalRacers));
		gPlayerData[playerid][pMoney] += moneyReward;
		GivePlayerMoney(playerid,moneyReward);

		new rank = GetPlayerRankByXP(gPlayerData[playerid][pXP]);
		gPlayerData[playerid][pRank] = rank;

		printf("[XP] %s получил %d XP (всего: %d) — ранг: %s", pname, xpReward, gPlayerData[playerid][pXP], RankNames[rank]);
		///
        SavePlayerData(playerid);
        UpdatePlayerRankHUD(playerid);
        TextDrawHideForPlayer(playerid, TRankHUD[playerid]);
    	TextDrawShowForPlayer(playerid, TRankHUD[playerid]);
        
		format(finishmsg, sizeof(finishmsg),"-> %s finished %d%s in %d:%s.%s", pname,gFinishOrder, append, Minutes, sSeconds, sMSeconds);
		SendClientMessageToAll(COLOR_TEMP,finishmsg);
	    DisablePlayerRaceCheckpoint(playerid);
	    PlaySoundForPlayer(playerid, 1183);
		if (GetPlayerMenu(playerid) != buildMenu[playerid])
		if (gPlayerData[playerid][pReady] && gTrackTime > 3)
		    showVoteTimer[playerid] = SetTimerEx("showVote", TIME_SHOW_VOTE, 0, "d", playerid);

		CheckAgainstHighScore(playerid, Time);

	} else {    //If they havent finished, set next checkpoint+more
		gPlayerProgress[playerid]++;        //Increase the players progress in the race
		RaceCheckpoints[gPlayerProgress[playerid]][3]++;
		gRacePosition[playerid]=floatround(RaceCheckpoints[gPlayerProgress[playerid]][3],floatround_floor);
		SetRaceText(playerid, gRacePosition[playerid]); //Set the race textdraws
		SetCheckpoint(playerid,gPlayerProgress[playerid],gMaxCheckpoints);  //Sets the next checkpoint in the race
		PlaySoundForPlayer(playerid, 1137);
	}
	return 1;
}




public OnVehicleSpawn(vehicleid)
{
	//Tried many ways to get rid of cars, found this was the least crashy (but still might be causing crashes)
	//If they car is spawning for the first time, nothing happends, if the car spawns for a second time (a respawn) it is destroyed.
	gVehDestroyTracker[vehicleid]++;
	if (gVehDestroyTracker[vehicleid]==1)
	{
		DestroyVehicle(vehicleid);
		gVehDestroyTracker[vehicleid]=0;
	}
}

//////////////////////////////////////////////////
//// x.x SA-MP FUNCTIONS (END) ///////////////////
//////////////////////////////////////////////////




//////////////////////////////////////////////////
//// x.x TEXTDRAW FUNCTIONS (START) //////////////
//////////////////////////////////////////////////
public updateTime()
{

	new Time, timestamp;
	timestamp = GetTickCount();
	if (gRaceStart != 0)
		Time = timestamp - gRaceStart;
	else
		Time=0;

	new MSeconds;
	timeconvert(Time, gMinutes, gSeconds, MSeconds);
	gindex=0;
	while (gSeconds > 9)
	{
		gSeconds-=10;
		gindex++;
	}
	new tmp[10];
	format(tmp,10,"%d:%d%d",gMinutes,gindex,gSeconds);
	TextDrawSetString(Ttime, tmp);
	printf("Ttime on update is %d", Ttime);


}

createTextDraws()
{
	Ttime = TextDrawCreate(563.0, 376.0, "0");
	printf("Ttime on creation is %d", Ttime);
	TextDrawLetterSize(Ttime, 0.6, 3);
	Ttotalracers = TextDrawCreate(590.0, 355.0, "/0");
	TextDrawLetterSize(Ttotalracers, 0.5, 2.5);
}

//////////////////////////////////////////////////
//// x.x TEXTDRAW FUNCTIONS (END) ////////////////
//////////////////////////////////////////////////


//////////////////////////////////////////////////
//// x.x COMMANDS (START) ////////////////////////
//////////////////////////////////////////////////


public OnPlayerCommandText(playerid, cmdtext[])
{
	dcmd(saverace,8,cmdtext);
	dcmd(set,3,cmdtext);
	dcmd(buildmode,9,cmdtext);
	dcmd(kill,4,cmdtext);
	dcmd(newcar,6,cmdtext);
	dcmd(nc,2,cmdtext);
	//dcmd(rescueme,8,cmdtext);
	dcmd(stopsound,9,cmdtext);
	dcmd(moretime,8,cmdtext);
	dcmd(ss,2,cmdtext);
	dcmd(record,7,cmdtext);
	dcmd(top5,4,cmdtext);
	dcmd(track,5,cmdtext);
	dcmd(pause,5,cmdtext);
	dcmd(unpause,7,cmdtext);
	dcmd(addtorotation,13,cmdtext);
	dcmd(help,4,cmdtext);
	dcmd(buildhelp,9,cmdtext);
	dcmd(ready, 5, cmdtext);
	dcmd(garage, 6, cmdtext);
	dcmd(shop, 4, cmdtext);
	dcmd(stadium, 7, cmdtext);
	dcmd(spawncar, 8, cmdtext);
	return 0;
}
dcmd_spawncar(playerid, params[])
{
	if (strlen(params) == 0)
	{
	    SendClientMessage(playerid, -1, "Использование: /spawncar [ModelID]");
	    return 1;
	}

	new modelid;
	if (!sscanf(params, "d", modelid))
	{
	    SendClientMessage(playerid, -1, "Использование: /spawncar [ModelID]");
	    return 1;
	}

	if (modelid < 400 || modelid > 611)
	{
	    SendClientMessage(playerid, -1, "Ошибка: ID машины должен быть от 400 до 611.");
	    return 1;
	}

	new Float:x, Float:y, Float:z, Float:angle;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, angle);

	x += 3.0 * floatsin(-angle, degrees);
	y += 3.0 * floatcos(-angle, degrees);

	new vehicleid = CreateVehicle(modelid, x, y, z, angle, -1, -1, 600);

	if (vehicleid != INVALID_VEHICLE_ID)
	{
	    // Устанавливаем интерьер и виртуальный мир, чтобы машина была видимой
	    LinkVehicleToInterior(vehicleid, GetPlayerInterior(playerid));
	    SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(playerid));

	    new msg[64];
	    format(msg, sizeof(msg), "Машина ID %d заспавнена.", modelid);
	    SendClientMessage(playerid, 0x00FF00FF, msg);
	}
	else
	{
	    SendClientMessage(playerid, -1, "Ошибка при создании машины.");
	}

	return 1;
}


dcmd_stadium(playerid, params[])
{
	if (strlen(params) == 0){
	    SendClientMessage(playerid, -1, "Использование: /stadium [1-6]");
	    return 1;
	}

	new id;
	if (!sscanf(params, "d", id)) {
	    SendClientMessage(playerid, -1, "Использование: /stadium [1-6]");
	    return 1;
	}

	new Float:x, Float:y, Float:z, interior;

	switch (id)
	{
	    case 1: { interior = 1;  x = -1402.66; y = 106.38;  z = 1032.27; }      // Oval Stadium
	    case 2: { interior = 16; x = -1401.06; y = 1265.37; z = 1039.86; }      // Vice Stadium
	    case 3: { interior = 15; x = -1417.89; y = 932.44;  z = 1041.53; }      // Blood Bowl
	    case 4: { interior = 14; x = -1420.42; y = 1616.92; z = 1052.53; }      // Kickstart
	    case 5: { interior = 7;  x = -1403.01; y = -250.45; z = 1043.53; }      // 8-Track
	    case 6: { interior = 4;  x = -1421.56; y = -663.82; z = 1059.55; }      // Dirtbike
	    default: {
	        SendClientMessage(playerid, -1, "Ошибка: введите число от 1 до 6.");
	        return 1;
	    }
	}

	SetPlayerPos(playerid, x, y, z);
	SetPlayerInterior(playerid, interior);

	new msg[128];
	format(msg, sizeof(msg), "Вы были телепортированы на стадион #%d (интерьер %d)", id, interior);
	SendClientMessage(playerid, 0x00FF00FF, msg);
	return 1;
}

dcmd_track(playerid, params[])  //Admin command to force a change to the specified track Usage: /track TRACKNAME
{
    if(!IsPlayerAdmin(playerid))
	{
		SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Извините, только админ может менять трассу");
		return 1;
	}
    if  (gTrackTime<=10)
    {
		SendClientMessage(playerid,COLOR_TEMP,"Слишком поздно, уже идет замена трассы");
		return 1;
	}
	new trackname[256];
	if (!sscanf(params, "s", trackname)) SendClientMessage(playerid, COLOR_TEMP, "Использование: /track [trackname]");
    new tmp[256],msg[256];
    format(tmp,256,"%s.race",trackname);
	if(!fexist(tmp))
	{
	    SendClientMessage(playerid, COLOR_TEMP,"404: Трасса не существует");
	    return 1;
	}
	format(msg,256,"Админ изменил трассу на: %s",trackname);
	printf("Меняем трассу на %s",trackname);
	SendClientMessageToAll(COLOR_TEMP,msg);
	gTrackTime=7;
	gNextTrack = trackname;
	#pragma unused playerid
    return 1;
}

garage(playerid) {
    TogglePlayerControllable(playerid,0);
    inCarsMenu[playerid] = 1;
    inGarageMenu[playerid] = 1;
    ShowMenuForPlayer(garageMenu,playerid);
}

shop(playerid) {
    TogglePlayerControllable(playerid,0);
    inCarsMenu[playerid] = 1;
    inGarageMenu[playerid] = 0;
    ShowMenuForPlayer(carShopMenu,playerid);
}

dcmd_garage(playerid, params[]) {
    garage(playerid);
    return 1;
}

dcmd_shop(playerid, params[]) {
    shop(playerid);
    return 1;
}

dcmd_ready(playerid, params[])
{
   #pragma unused params
	
	
    gPlayerData[playerid][pReady] = !gPlayerData[playerid][pReady];

    new status[16];

    if (gPlayerData[playerid][pReady])
    {
		SendClientMessage(playerid, -1, "{00DDDD}[СТАТУС]{FFFFFF} Вы отмечены как {00FF00}ГОТОВЫЙ{FFFFFF} для следующей гонки.");
        format(status, sizeof(status), "~g~READY");

		Tposition[playerid] = TextDrawCreate(560.0, 330.0, " ");
		TextDrawLetterSize(Tposition[playerid], 1.2, 6.2);
		Tappend[playerid] = TextDrawCreate(590.0, 335.0, " ");
		TextDrawLetterSize(Tappend[playerid], 0.5, 2.5);
			
        // Если это первый готовый игрок, запустить гонку
        new readyCount = 0;
        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && i != playerid && gPlayerData[i][pReady])
                readyCount++;
        }

        if (gTrackTime > 10) // никто больше не готов и гонка ещё не идёт
        {
			gTotalRacers++;
			new tmp[5];
			format(tmp, sizeof(tmp), "/%d", gTotalRacers);

			TextDrawSetString(Ttotalracers, tmp);
			TextDrawShowForPlayer(playerid, Ttime);
			TextDrawShowForPlayer(playerid, Tappend[playerid]);
			TextDrawShowForPlayer(playerid, Tposition[playerid]);
			TextDrawShowForPlayer(playerid, Ttotalracers);

            GridSetupPlayer(playerid);
            SetTimerEx("GridSetup", TIME_GIVE_CAR, 0, "d", playerid);
            if (readyCount == 0) {
                gTrackTimeSaved = gTrackTime;
            }
            if (gTrackTimeSaved != 0 && abs(gTrackTime - gTrackTimeSaved) > 10) {
                gTrackTimeSaved = 0;
                invalidateResult = 1;
            }
        }
    }
    else
    {
		SendClientMessage(playerid, -1, "{00DDDD}[СТАТУС]{FFFFFF} Вы отмечены как {FF0000}НЕ ГОТОВЫЙ{FFFFFF}.");
        format(status, sizeof(status), "~r~NOT READY");
    }

    GameTextForPlayer(playerid, status, 2000, 3);
    UpdatePlayerRankHUD(playerid);
    return 1;
}

abs(a) {
    if (a > 0)
        return a;
    return -a;
}



dcmd_addtorotation(playerid, params[]) //Admin command to add a user-made track to the rotation list Usage: /addtorotation TRACKNAME
{
	if(!IsPlayerAdmin(playerid))
	{
		SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Только админ может вносить трассы в треклист");
		return 1;
	}
	new trackname[128];
	if (!sscanf(params, "s", trackname)) SendClientMessage(playerid, COLOR_TEMP, "[ОШИБКА] Использование: /track [trackname]");
    new tmp[256];
    format(tmp,256,"%s.race",trackname);
	if(!fexist(tmp))
	{
	    SendClientMessage(playerid, COLOR_TEMP,"[ОШИБКА] 404: Трассе не существует");
	    return 1;
	}
	
	new File:f;
	if(fexist("racenames.txt"))
	{
	    new msg[256];
		f = fopen("racenames.txt", io_append);
		format(tmp,256,"\n%s",trackname);
		fwrite(f,tmp);
		fclose(f);
		format(msg,256,"[УСПЕШНО] Добавил %s в ротацию",trackname);
		SendClientMessage(playerid,COLOR_TEMP,msg);
	}
	
    return 1;
}

dcmd_stopsound(playerid, const params[]) //Stops the annoying music
{
	PlaySoundForPlayer(playerid, 1186);
	#pragma unused params
	return 1;
}

dcmd_ss(playerid, const params[]) //Shortcut for stopping the annoying music
{
	PlaySoundForPlayer(playerid, 1186);
	#pragma unused params
	return 1;
}
dcmd_moretime(playerid, const params[])//Admin command to add 35 seconds onto the current track time
{
	if(!IsPlayerAdmin(playerid))
	{
		SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Извините, только админ может добавлять время в трассу");
		return 1;
	}
    #pragma unused params
    #pragma unused playerid
	gTrackTime+=35;
	return 1;
}
dcmd_top5(playerid, const params[]) //Shows the top5 times for the current track
{
    #pragma unused params
	ReadHighScoreList(gTrackName, 1, playerid, 0);
	return 1;
}
dcmd_record(playerid, const params[])
{
    #pragma unused params
	if (strlen(gBestTime) > 0) SendClientMessage(playerid, COLOR_TEMP, gBestTime);
 	return 1;
}

dcmd_rescueme(playerid, const params[]) //Returns you to the start of the race
{
    #pragma unused params
	new State = GetPlayerState(playerid);
	SendClientMessage(playerid, COLOR_TEMP, "Отправляю тебя на старт.");
	if (State!=1)
	{
		RemovePlayerFromVehicle(playerid);
		SetTimerEx("GridSetup",TIME_GIVE_CAR*2,0,"d",playerid);
		SetTimerEx("GridSetupPlayer", TIME_MOVE_PLAYER,0,"d", playerid);
	} else if (State==1) {
		GridSetupPlayer(playerid);
		SetTimerEx("GridSetup", TIME_GIVE_CAR,0,"d", playerid);
	}
	/*while (gPlayerProgress[playerid]>=0)
	{
		RaceCheckpoints[gPlayerProgress[playerid]][3]--;
		gPlayerProgress[playerid]--;
	}*/

 	return 1;
}

dcmd_pause(playerid, const params[])  //Admin command to pause the countdown to the next track (note: does not stop players, simply use if you need to extend the time for the track)
{
	if(!IsPlayerAdmin(playerid))
	{
		SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Только админ может останавливать и продолжать трассу");
		return 1;
	}
    #pragma unused params
	KillTimer(gEndRacetimer);
	SendClientMessageToAll(COLOR_TEMP,"[ИНФО] Админ поставил трассу на паузу!");
	SendClientMessage(playerid,COLOR_TEMP,"[ИНФО] Трек остановлен, чтобы продолжить /unpause");
 	return 1;
}
dcmd_unpause(playerid, const params[])
{
	if(!IsPlayerAdmin(playerid))
	{
		SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Только админ может останавливать и продолжать трассу");
		return 1;
	}
    #pragma unused params
 	KillTimer(gEndRacetimer);
	gEndRacetimer = SetTimer("nextRaceCountdown",1000,1);
	SendClientMessageToAll(COLOR_TEMP,"[ИНФО] Админ снял паузу с текущей трассы!");
	SendClientMessage(playerid,COLOR_TEMP,"[ИНФО] Пауза снята");
 	return 1;
}
dcmd_newcar(playerid, const params[]) //Gives the player a replacement car
{
    #pragma unused params
    if (xRaceBuilding[playerid]==0 && newcar[playerid]==SPARE_CARS)
    {
        SendClientMessage(playerid, COLOR_TEMP, "[ОШИБКА] Вы уже израсходовали свои запасные автомобили этой гонки");
        return 1;
    }
	newCar(playerid);
	if (xRaceBuilding[playerid]==0)
	{
		new msg[256];
		format(msg,256,"[ИНФО] Выдаем запасной автомобиль. Тебе доступно %d запасных автомобилей за гонку.",SPARE_CARS);
		SendClientMessage(playerid, COLOR_TEMP, msg);
		newcar[playerid]++;
	}
 	return 1;
}
dcmd_nc(playerid, const params[]) //Gives the player a replacement car
{
    #pragma unused params
    if (xRaceBuilding[playerid]==0 && newcar[playerid]==SPARE_CARS)
    {
        SendClientMessage(playerid, COLOR_TEMP, "[ОШИБКА] Вы уже израсходовали свои запасные автомобили этой гонки");
        return 1;
    }
	newCar(playerid);
	if (xRaceBuilding[playerid]==0)
	{
		new msg[256];
		format(msg,256,"[ИНФО] Выдаем запасной автомобиль. Тебе доступно %d запасных автомобилей за гонку.",SPARE_CARS);
		SendClientMessage(playerid, COLOR_TEMP, msg);
		newcar[playerid]++;
	}
 	return 1;
}
dcmd_kill(playerid, const params[]) //Use to kill yourself
{
    #pragma unused params
	SetPlayerHealth(playerid,0.0);
 	return 1;
}
	
dcmd_help(playerid, const params[])
{
    #pragma unused params
    SendClientMessage(playerid,COLOR_TEMP,"Доступные команды: '/newcar' '/nc' '/rescueme' '/ready'");
	if(IsPlayerAdmin(playerid))SendClientMessage(playerid,COLOR_TEMP,"Админ команды: '/pause' '/resume' '/track [racename]' '/addmodetorotation [racename]'");
 	return 1;
}
dcmd_buildhelp(playerid, const params[])
{
    #pragma unused params
	SendClientMessage(playerid,COLOR_TEMP,"Доступные команды: '/buildmode on' '/buildmode off' '/set [racename]' '/newcar'");
 	return 1;
}


dcmd_buildmode(playerid, params[])
{
	new var1[256];
    if (!sscanf(params, "s", var1))
	{
		SendClientMessage(playerid, COLOR_TEMP, "Использование: /buildmode [on/off]");
		return 1;
	}
	if (strcmp(var1, "on", true)==0)
	{
		xRaceBuilding[playerid]=1;
		RemovePlayerFromVehicle(playerid);
		xPlayerProgress[playerid]=0;
		AllowPlayerTeleport(playerid,true);
		//SetPlayerVirtualWorld(playerid,playerid+1);

		xWorldTime[playerid]=0;
		xTrackTime[playerid]=0;
		xWeatherID[playerid]=0;
		xRaceType[playerid]=0;
		xCarIds[playerid][0]=0;

		SendClientMessage(playerid,COLOR_TEMP,"Заходим в режим строительства!");
		gPlayerProgress[playerid]=0;

		DisablePlayerRaceCheckpoint(playerid);
		TogglePlayerControllable(playerid, 0);
		xCarIds[playerid][0]=0;
		ShowMenuForPlayer(buildMenu[0],playerid);

		GetPlayerName(playerid, xCreatorName[playerid],MAX_PLAYER_NAME);
		for (new i;i< MAX_RACECHECKPOINTS;i++)
		{
			xRaceCheckpoints[playerid][i][0]=0;
			xRaceCheckpoints[playerid][i][1]=0;
			xRaceCheckpoints[playerid][i][2]=0;
			xRaceCheckpoints[playerid][i][3]=0;
		}
	}
	if (strcmp(var1, "off", true)==0)
	{
		xRaceBuilding[playerid]=0;
		SendClientMessage(playerid,COLOR_TEMP,"Выходим из режима строительства!");
		TogglePlayerControllable(playerid,1);
		AllowPlayerTeleport(playerid,false);
	    RemovePlayerFromVehicle(playerid);
	    SetPlayerVirtualWorld(playerid,gWorldID);
		SetTimerEx("GridSetup",TIME_GIVE_CAR*2,0,"d",playerid);
		SetTimerEx("GridSetupPlayer", TIME_MOVE_PLAYER,0,"d", playerid);
		DisablePlayerRaceCheckpoint(playerid);
		SetCheckpoint(playerid,gPlayerProgress[playerid],gMaxCheckpoints);
		xCarIds[playerid][0]=0;

		
	}
 	return 1;
}


dcmd_set(playerid, params[])
{
    
	if (xRaceBuilding[playerid]>0)
	{

	        if (!sscanf(params, "s", xRaceName[playerid])) SendClientMessage(playerid, COLOR_TEMP, "[ОШИБКА] Использование: /set [value]");
	        //modename
			new trackname[256];
			format(trackname,256,"%s.race",xRaceName[playerid]);
			if (fexist(trackname))
			{
				SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Этот трек уже существует, выбери другой.");
				return 1;
			} else if (CheckSafeInput(xRaceName[playerid])==0)
			{
				SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Ошибка: Используй только a-z,A-Z,-,_,0-9");
				return 1;
			}
			xRaceBuilding[playerid]++;
			new msg[256];
			format(msg,256,"Modename set to: %s",xRaceName[playerid]);
			SendClientMessage(playerid,COLOR_TEMP,msg);
			TogglePlayerControllable(playerid,1);
			SendClientMessage(playerid,COLOR_TEMP,"[ИНФО] Используй FIRE для задания стартово позиции для игрока 1 (1ая позиция в решетке)");
	}
 	return 1;
}

dcmd_saverace(playerid, const params[])
{
    #pragma unused params
	if(xRaceBuilding[playerid]>0 && xPlayerProgress[playerid]>3)
	{
		if (xCarIds[playerid][0]<300)xCarIds[playerid][0]=565;
		SaveRace(playerid);
		xRaceBuilding[playerid]=0;
		SetVehicleToRespawn(GetPlayerVehicleID(playerid));
		SendClientMessage(playerid,COLOR_TEMP,"Выходим из режима строительства!");
		new State = GetPlayerState(playerid);
		if (State>1) RemovePlayerFromVehicle(playerid);
	    SetPlayerVirtualWorld(playerid,gWorldID);
		DisablePlayerRaceCheckpoint(playerid);
		SetTimerEx("GridSetup",TIME_GIVE_CAR*2,0,"d",playerid);
		SetTimerEx("GridSetupPlayer", TIME_MOVE_PLAYER,0,"d", playerid);
		TogglePlayerControllable(playerid,1);
		new msg[256],pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid,pname,MAX_PLAYER_NAME);
		format (msg,256,"%s создал трассу: %s",pname,xRaceName[playerid]);
		SendClientMessageToAll(COLOR_TEMP,msg);
		xCarIds[playerid][0]=0;
	} else {
	    SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Недостаточно информации!");
	}
 	return 1;
}
//////////////////////////////////////////////////
//// x.x COMMANDS (END) //////////////////////////
//////////////////////////////////////////////////






//////////////////////////////////////////////////
//// x.x CUSTOM FUNCTIONS (START) ////////////////
//////////////////////////////////////////////////
IsKeyJustDown(key, newkeys, oldkeys)
{
	if((newkeys & key) && !(oldkeys & key)) return 1;
	return 0;
}

newCar(playerid)
{
	new State = GetPlayerState(playerid);
	if (State>1) RemovePlayerFromVehicle(playerid);
    if (xRaceBuilding[playerid]<5 && State>1 )SetTimerEx("giveCar",6000,0,"ddd",playerid, gCarModelID,0);
    else if (xRaceBuilding[playerid]<5 && State==1)giveCar(playerid, gCarModelID, 0);
	else if (xCarIds[playerid][0]>300 && State>1)SetTimerEx("giveCar",6000,0,"ddd",playerid, xCarIds[playerid][0],playerid+1);
	else if (xCarIds[playerid][0]>300 && State==1)giveCar(playerid, xCarIds[playerid][0], playerid+1);
 	return 1;

}

public respawnCar(veh)
{
	SetVehicleToRespawn(veh);
}
public giveCar(playerid, modelid, world)
{
	new Float:pos[4];
	GetPlayerPos(playerid, pos[0],pos[1],pos[2]);
	GetPlayerFacingAngle(playerid,pos[3]);
	new State = GetPlayerState(playerid);
	if (State>1)
	{
        RemovePlayerFromVehicle(playerid);
	    gGiveCarTimer[playerid] = SetTimerEx("giveCar",TIME_GIVE_CAR,0,"dd",playerid, modelid);
	} else {
		
		//vehicles[playerid] =
		//new temp = CreateVehicle(modelid,pos[0],pos[1],pos[2],pos[3],-1,-1,10);
		new temp = CreateVehicle(CurrentCar(playerid),pos[0],pos[1],pos[2],pos[3],CurrentColor(playerid),-1,10);
		printf("racebuilding %d; pworld:%d",xRaceBuilding[playerid], playerid+100);
		if (xRaceBuilding[playerid]<5)
		{
			SetVehicleVirtualWorld(temp, gWorldID);
		} else {
			SetVehicleVirtualWorld(temp, playerid+100);
			printf("VehicleVirtual: %d world:%d",temp, playerid+100);
		}
		processCarProperty(playerid, temp);
		
		SetTimerEx("PutPlayerInVehicleTimed",TIME_PUT_PLAYER,0,"ddd",playerid, temp,0);
		SetCameraBehindPlayer(playerid);
	}
	return;
	
}

processCarProperty(playerid, vehicleid) {		
	// rent system: has to subtract one
	new health = gPlayerData[playerid][pBoughtCarsHealth][gPlayerData[playerid][pCurrentCar]];
	if(gPlayerData[playerid][pCurrentRent]==1 && gPlayerData[playerid][pRentedCarRaces][gPlayerData[playerid][pCurrentCar]] != 0) {
		gPlayerData[playerid][pRentedCarRaces][gPlayerData[playerid][pCurrentCar]] -= 1;
	} else if (gPlayerData[playerid][pCurrentRent]==0 && health >= 25) {
	    SetVehicleHealth(vehicleid, health * 10);
	    playerCreatedVehicle[playerid] = vehicleid;
	}
	    
	// some payments from car owner?
}

public DestroyAllVehicles()
{
	for(new i=0;i<5;i++)
	{
		destroyCarSafe(i);
	}
}

public destroyCarSafe(veh)
{
	if(veh == -1) return 1;
	for(new i;i<MAX_PLAYERS;i++)
	{
		if(IsPlayerInVehicle(i,veh))
		{
			RemovePlayerFromVehicle(i);
			SetTimerEx("destroyCarSafe",2000,0,"d",veh);
			return 0;
		}
	}
	DestroyVehicle(veh);
	return 1;
}



main()
{
	print("\n----------------------------------");
	print(" Adrenaline 2.0 by Paige");
	print("----------------------------------\n");
}




CheckSafeInput(input[])//CREDIT: Based off Simon's ConvertToSafeInput
{
	new len = strlen(input), idx = 0;
	while (idx < len)
	{
	    if (!((input[idx] >= 48  && input[idx] <= 57) || (input[idx] >= 65 && input[idx] <= 90)  || (input[idx] >= 97 && input[idx] <= 122)|| input[idx] == 45 || input[idx] == 95|| input[idx] == 91 || input[idx] == 93))
	    {
           return 0;
	    }
	    else idx++;
	}
	return 1;
}

createVote()
{
    for (new i;i<4;i++) gVoteItems[i] = "RESET";
	DestroyMenu(voteMenu);
	voteMenu = CreateMenu("Vote",1, 50.0, 200.0, 120.0, 250.0);
	print("Creating Votemenu");
	for (new i=0;i<4;i++)
	{
	    randomRaceName(i,gRaces);
		AddMenuItem(voteMenu,0,gVoteItems[i]);
		printf("VoteOption%d: %s",i,gVoteItems[i]);
	}
	for (new i=0;i<4;i++)gVotes[i]=0;

}


randomRaceName(index,num)
{
	new length = sizeof(gRaceNames);
	length--;
	new rand = random(num);
	for(new i;i<4;i++)
	{
		if (strcmp(gRaceNames[rand], gVoteItems[i], true)==0)
		{
			randomRaceName(index,num);
			return 1;
		}
	}
	gVoteItems[index] = gRaceNames[rand];
	return 1;
}
/*

randomRaceName(array[],num)
{
	new length = strlen(array);
	new rand = random(num);
	for(new i;i<length;i++)
	{
		if (strcmp(array[rand], array[i], true)==0)
		{
			randomRaceName(array[],num);
			return 1;
		}
	}
	return array[rand];
}
*/

createBuildMenus()
{

	buildMenu[0] = CreateMenu("World Time",1, 200.0, 125.0, 220.0, 50.0);
	SetMenuColumnHeader(buildMenu[0], 0, "Select The Time");
	AddMenuItem(buildMenu[0],0,"0:00");
	AddMenuItem(buildMenu[0],0,"3:00");
	AddMenuItem(buildMenu[0],0,"6:00");
	AddMenuItem(buildMenu[0],0,"9:00");
	AddMenuItem(buildMenu[0],0,"12:00");
	AddMenuItem(buildMenu[0],0,"15:00");
	AddMenuItem(buildMenu[0],0,"18:00");
	AddMenuItem(buildMenu[0],0,"21:00");

	buildMenu[1] = CreateMenu("Weather",1, 200.0, 125.0, 220.0, 50.0);
	SetMenuColumnHeader(buildMenu[1], 0, "Select the Weather");
	AddMenuItem(buildMenu[1],0,"Normal");
	AddMenuItem(buildMenu[1],0,"Sunny");
	AddMenuItem(buildMenu[1],0,"Grey");
	AddMenuItem(buildMenu[1],0,"Rainy");
	AddMenuItem(buildMenu[1],0,"Storm");
	AddMenuItem(buildMenu[1],0,"Foggy");

	buildMenu[2] = CreateMenu("TrackTime",1, 200.0, 125.0, 220.0, 50.0);
	SetMenuColumnHeader(buildMenu[2], 0, "Select the Track Time");
	AddMenuItem(buildMenu[2],0,"1 minute");
	AddMenuItem(buildMenu[2],0,"2 minutes");
	AddMenuItem(buildMenu[2],0,"3 minutes");
	AddMenuItem(buildMenu[2],0,"4 minutes");
	AddMenuItem(buildMenu[2],0,"5 minutes");
	AddMenuItem(buildMenu[2],0,"6 minutes");
	AddMenuItem(buildMenu[2],0,"8 minutes");
	AddMenuItem(buildMenu[2],0,"10 minutes");
	AddMenuItem(buildMenu[2],0,"15 minutes");

	buildMenu[3] = CreateMenu("RaceType",1, 200.0, 125.0, 220.0, 50.0);
	SetMenuColumnHeader(buildMenu[3], 0, "Select the type of race");
	AddMenuItem(buildMenu[3],0,"Normal");
	AddMenuItem(buildMenu[3],0,"Flying");

	buildMenu[4] = CreateMenu("Vehicle",1, 200.0, 125.0, 220.0, 50.0);
	SetMenuColumnHeader(buildMenu[4], 0, "Select the Vehicle");
	AddMenuItem(buildMenu[4],0,"Turismo");
	AddMenuItem(buildMenu[4],0,"Flash");
	AddMenuItem(buildMenu[4],0,"Banshee");
	AddMenuItem(buildMenu[4],0,"Cheetah");
	AddMenuItem(buildMenu[4],0,"Uranus");
	AddMenuItem(buildMenu[4],0,"NRG 500");
	AddMenuItem(buildMenu[4],0,"Sanchez");
	AddMenuItem(buildMenu[4],0,"Stunt Plane");
	AddMenuItem(buildMenu[4],0,"Speeder (Boat)");
	AddMenuItem(buildMenu[4],0,"More...");

	buildMenu[5] = CreateMenu("Vehicle2",1, 200.0, 125.0, 220.0, 50.0);
	SetMenuColumnHeader(buildMenu[5], 0, "Select the Vehicle");
	AddMenuItem(buildMenu[5],0,"Sultan");
	AddMenuItem(buildMenu[5],0,"SuperGT");
	AddMenuItem(buildMenu[5],0,"Savanna");
	AddMenuItem(buildMenu[5],0,"BF Injection");
	AddMenuItem(buildMenu[5],0,"Monster");
	AddMenuItem(buildMenu[5],0,"Bullet");
	AddMenuItem(buildMenu[5],0,"Hotring");
	AddMenuItem(buildMenu[5],0,"Kart");
	AddMenuItem(buildMenu[5],0,"Hydra");//520
	AddMenuItem(buildMenu[5],0,"Back...");//back
}

public showVote(playerid)
{
		TogglePlayerControllable(playerid,0);
		if (racecount+1 != RACES_TILL_MODECHANGE) ShowMenuForPlayer(voteMenu,playerid);
}
public countVotes()
{
	new votes, equalvotes[4],equal, index=-1, vmsg[156];
	for (new i=0;i<4;i++)
	{
		if(gVotes[i]>votes)
		{
			votes=gVotes[i];
			index=i;
			equal=0;
			equalvotes[equal]=i;
		} else if (gVotes[i]==votes && votes!=0)
		{
		    equal++;
		    equalvotes[equal]=i;

		}
		
	}

	if (votes > 0)
	{
	    new rand = random(equal + 1);
	    gNextTrack = gVoteItems[equalvotes[rand]];
	    gTrackTime = 7;
	
	    format(vmsg, sizeof(vmsg), "{00DDDD}[ГОНКА]{FFFFFF} Голосование завершено! {FFD700}%s{FFFFFF} побеждает с {FF5500}%d{FFFFFF} голосами. Переход через 10 секунд...", gVoteItems[equalvotes[rand]], gVotes[index]);
	    SendClientMessageToAll(-1, vmsg);
	}
	else
	{
	    new rand = random(4);
	    gNextTrack = gVoteItems[rand];
	
	    format(vmsg, sizeof(vmsg), "{00DDDD}[ГОНКА]{FFFFFF} Голосование завершено! Голосов не было. Случайно выбрана трасса: {FFD700}%s{FFFFFF}. Переход через 10 секунд...", gVoteItems[rand]);
	    SendClientMessageToAll(-1, vmsg);
	}
	

}


public RemovePlayersFromVehicles()
{
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		if (!IsPlayerConnected(i)) continue;

		new State = GetPlayerState(i);
		if (xRaceBuilding[i] == 0 && State > 1 && gPlayerData[i][pIngame] == 1)
		{
			RemovePlayerFromVehicle(i);
			// Готовый игрок — просто замораживаем его машину
			new veh = GetPlayerVehicleID(i);
			for (new j = 0; j < MAX_PLAYERS; j++)
			{
				SetVehicleParamsForPlayer(veh, j, 0, 1);
			}
			if (!gPlayerData[i][pReady])
			{
				// НЕ ГОТОВ — безопасный телепорт
				SetPlayerVirtualWorld(i, 0);
				gPlayerData[i][pIngame] = 0;
				SetPlayerPos(i, 27.24 + float(random(2)), 3422.45, 6.2);
				SetPlayerFacingAngle(i, 270.0);
				SetCameraBehindPlayer(i);
				continue;
			}
		}
	}
}


public changetrack()
{
	printf("Меняю трек:%s",gNextTrack);
	invalidateResult = 0;
	if(LoadRace(gNextTrack))
	{
		gGridIndex=0;
		gGrid2Index=0;
	    printf("DEBUG changetrack");

		for (new i=0;i<MAX_PLAYERS;i++)
		{
			gScores2[i][0]=gScores[i][0];
			gScores2[i][1]=gScores[i][1];
			gGrided[i]=0;
			newcar[i]=0;
		}
		quickSort(200);
		if(gWorldID==100) gWorldID=1;
		else gWorldID++;
		//CreateVehicles(200);
		AddPlayersToRace(200);
		SetTimerEx("AddRacers",TIME_GIVE_CAR,0,"d", 200);

	}

}

CreateSIObjects(playerid)
{
	// Create variable
	new TempObjectNumber;

    // Create stunt island player objects (with draw distance of 999m)
    CreatePlayerObject(playerid,19672,331.9166,3396.5845,85.9599,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19532,77.5000,3570.0000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19542,335.0000,3570.0000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19540,335.0000,3757.5000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19532,7.5000,3500.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19535,77.5000,3422.5000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19532,7.5000,3640.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19532,-62.5000,3570.0000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19539,335.0000,3663.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19533,77.5000,3678.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19533,77.5000,3461.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19542,7.5000,3835.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19533,-62.5000,3678.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19531,-132.5000,3570.0000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19538,-132.5000,3678.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19532,-132.5000,3500.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19534,-62.5000,3500.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19534,-62.5000,3640.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19541,-62.4998,3835.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19541,84.9997,3827.5000,4.3078,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19538,-132.5000,3461.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19532,-132.5000,3640.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19533,-62.5000,3461.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19532,7.5000,3422.5000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19532,-132.5000,3422.5000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19538,-132.5000,3383.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19542,-55.0000,3227.5000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19545,-62.5000,3383.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19543,-202.5000,3383.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19533,-202.5000,3461.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19541,15.0001,3352.5000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19541,77.5000,3835.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19541,-62.5000,3165.0000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19542,-132.5000,3165.0000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19541,-202.5000,3165.0000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19539,-210.0000,3383.7500,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19541,-210.0000,3422.5000,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19539,-210.0000,3461.2500,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19541,-210.0000,3499.9998,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19532,-202.5000,3570.0000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19533,-202.5000,3678.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19542,-210.0000,3570.0000,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19541,-210.0000,3640.0000,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19539,-210.0000,3678.7500,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19541,-202.4998,3710.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19540,335.0000,3257.5000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19546,85.0000,3352.5000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19547,-132.5000,3290.0000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19546,-54.9999,3352.5000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19543,-62.5000,3321.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19543,-62.5000,3258.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19536,-132.5000,3196.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19543,-62.5000,3196.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19540,-55.0000,3165.0000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19542,-210.0000,3290.0000,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19543,-202.5000,3321.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19543,-202.5000,3258.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19543,-202.5000,3196.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19539,-210.0000,3196.2500,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19546,84.9999,3757.5000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19532,77.5000,3772.5000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19539,178.7500,3757.5000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19540,85.0000,3835.0000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19540,-69.9998,3835.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19546,-69.9998,3710.0000,4.3080,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19532,-62.4999,3772.5000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19539,-163.7498,3710.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19539,-69.9998,3803.7500,4.3077,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19539,335.0000,3726.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19529,7.5000,3570.0000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19539,241.2500,3757.5000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19539,303.7500,3757.5000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19539,241.2500,3257.5000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19539,303.7500,3257.5000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19535,-62.5000,3422.5000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19535,-202.5000,3422.5000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19535,-202.5000,3500.0000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19535,-202.5000,3640.0000,4.3077,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19535,77.5000,3640.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,149.4099,3422.5000,-40.2988,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19646,300.0856,3261.5845,83.4814,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19642,124.1813,3422.5000,8.8521,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19647,134.1813,3422.5000,8.8520,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19650,96.9146,3422.5000,6.1717,0.0000,-10.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19643,114.1813,3422.5000,8.8521,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19659,-15.6602,3682.0776,29.3538,0.0000,0.0000,0.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19665,311.1857,3531.0288,86.7789,0.0000,0.0000,-90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "YellowDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19667,305.6357,3426.5845,95.3124,0.0000,0.0000,-90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "BlueDirt1", 0);

	CreatePlayerObject(playerid,19664,70.0058,3666.1621,31.6038,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19663,331.9166,3381.5845,81.2314,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19661,326.6671,3417.2505,83.4814,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19662,337.7673,3671.4116,87.1412,0.0000,0.0000,90.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19651,284.1701,3276.5845,73.4814,0.0000,0.0000,90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,266.0011,3406.5845,53.4814,0.0000,0.0000,180.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	CreatePlayerObject(playerid,19660,316.0011,3245.9185,83.4814,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,188.5509,3422.5000,25.7300,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19649,203.5318,3422.5000,26.3325,0.0000,20.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19674,200.6326,3498.2903,17.2481,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19676,140.8339,3498.2903,12.0060,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19673,231.6195,3422.5000,36.5668,0.0000,15.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19675,144.5353,3422.5000,9.2890,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19678,120.0057,3697.9932,51.5540,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19675,154.9452,3422.5000,10.6383,0.0000,5.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19675,165.1978,3422.5000,12.8897,0.0000,10.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19675,175.2152,3422.5000,16.0262,0.0000,15.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19670,255.9339,3422.5000,-7.4172,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19673,241.1739,3422.5000,39.5792,0.0000,10.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19673,250.9545,3422.5000,41.7474,0.0000,5.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19673,260.8867,3422.5000,43.0549,0.0000,0.0000,180.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,266.0011,3406.5845,73.4814,0.0000,0.0000,180.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	CreatePlayerObject(playerid,19649,291.0011,3422.5000,83.4814,0.0000,-0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19670,291.0011,3422.5000,33.4567,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19684,314.6369,3697.9932,126.3243,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19682,213.1957,3717.7407,29.3538,0.0000,0.0000,-135.0000,999.0);
	CreatePlayerObject(playerid,19681,157.1870,3668.5852,29.3538,0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19686,260.6396,3739.9441,70.3298,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19685,181.5493,3697.9929,58.8229,0.0000,-30.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19663,331.9166,3331.5845,81.2314,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,331.9167,3356.5845,33.4567,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19663,331.9166,3281.5845,81.2314,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19646,300.0856,3271.5845,83.4814,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19670,331.9166,3306.5845,33.4567,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19649,300.0856,3301.5845,63.4814,0.0000,-0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19649,300.0856,3351.5845,63.4814,0.0000,-0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19649,300.0856,3401.5845,63.4814,0.0000,-0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19670,300.0855,3356.5845,13.4567,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,300.0856,3306.5845,13.4567,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19649,311.1857,3451.5845,63.4814,0.0000,-0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19649,311.1857,3501.5845,63.4814,0.0000,-0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19670,311.1857,3466.5845,13.4567,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,311.1858,3516.5845,13.4567,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19649,311.1857,3575.2466,87.1413,0.0000,-0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19663,311.1858,3625.2466,84.8912,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19670,311.1857,3560.2466,37.1166,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19661,316.4353,3660.9126,87.1412,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19670,311.1857,3625.2466,32.6165,0.0000,0.0000,90.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,358.9323,3682.0776,97.1412,0.0000,0.0000,-90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,358.9323,3682.0776,117.1413,0.0000,0.0000,-90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19667,95.0057,3729.8225,46.0054,-90.0000,0.0000,0.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "BlueDirt1", 0);

	CreatePlayerObject(playerid,19662,337.7672,3692.7434,127.1412,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19684,290.5576,3697.9929,119.8723,0.0000,15.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19649,257.7041,3697.9929,101.8476,0.0000,-30.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19649,214.4028,3697.9929,76.8476,0.0000,-30.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19685,157.4701,3697.9929,52.3709,0.0000,-15.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19670,149.8595,3697.9929,1.6564,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19670,343.0168,3682.0776,37.1165,0.0000,0.0000,90.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19667,95.0057,3729.8225,34.9053,-90.0000,0.0000,0.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "BlueDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19668,124.6504,3397.5898,84.0644,0.0000,15.0000,-90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "BlueDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19666,159.4614,3413.4658,108.9914,0.0000,0.0000,90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "YellowDirt1", 0);

	CreatePlayerObject(playerid,19680,70.0058,3697.9932,29.3538,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19670,25.0058,3697.9932,-20.6709,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19649,20.0058,3697.9932,29.3539,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19659,-15.6602,3682.0776,34.8538,180.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19649,20.0058,3666.1621,29.3538,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19649,120.0058,3666.1621,29.3538,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19670,25.0058,3666.1621,-20.6709,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19664,241.2924,3679.2480,31.6038,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19649,185.1914,3693.1628,29.3538,0.0000,0.0000,-135.0000,999.0);
	CreatePlayerObject(playerid,19661,236.0429,3714.9141,29.3538,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19670,125.0058,3666.1621,-20.6709,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19648,241.2924,3599.2480,29.3538,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19644,110.4799,3498.2903,11.5691,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19670,241.2924,3679.2480,-16.1709,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19647,241.2924,3569.2480,29.3539,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19664,241.2924,3489.2480,31.6038,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,241.2924,3489.2480,-16.1709,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19663,241.2924,3419.2480,27.1038,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19646,241.2924,3459.2480,29.3538,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19646,241.2924,3449.2480,29.3538,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19664,241.2924,3369.2480,31.6038,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,241.2924,3369.2480,-16.1709,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19663,241.2924,3319.2480,27.1038,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19661,236.0429,3283.5820,29.3538,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19661,235.9641,3283.5449,34.8538,-180.0000,0.0000,179.0000,999.0);
	CreatePlayerObject(playerid,19649,200.3770,3278.3325,29.3538,0.0000,-0.0000,-0.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,175.3770,3294.2480,39.3538,0.0000,0.0000,0.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,175.3770,3294.2480,59.3538,0.0000,0.0000,0.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,175.3769,3294.2480,79.3538,0.0000,0.0000,0.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,175.3770,3294.2480,44.8538,180.0000,0.0000,-180.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,175.3769,3294.2480,99.3538,0.0000,0.0000,0.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	CreatePlayerObject(playerid,19670,185.3770,3278.3325,-20.6709,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19661,164.7110,3283.5820,109.3538,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19649,159.4614,3319.2480,109.3538,0.0000,-0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19649,159.4614,3369.2480,109.3538,0.0000,-0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19670,159.4614,3364.2480,59.3291,0.0000,0.0000,90.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19666,159.4614,3487.1279,85.3316,0.0000,0.0000,90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "YellowDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19666,159.4614,3560.7900,61.6717,0.0000,0.0000,90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "YellowDirt1", 0);

	CreatePlayerObject(playerid,19670,119.1004,3385.7981,-1.9767,0.0000,0.0000,90.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19649,159.4614,3442.9102,85.6940,0.0000,-0.0000,-90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "YellowDirt1", 0);

	CreatePlayerObject(playerid,19684,159.4614,3667.4851,81.6925,0.0000,-30.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19649,159.4614,3634.6316,63.6678,0.0000,30.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19684,159.4614,3691.5645,88.1445,0.0000,-15.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19661,164.7109,3734.6946,88.9614,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19670,159.4614,3714.0286,38.9367,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19661,283.7699,3734.6946,69.5128,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19684,187.8412,3739.9441,88.1445,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19649,224.2404,3739.9441,79.2371,0.0000,-15.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19670,273.1040,3739.9441,19.4881,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19646,289.0194,3719.0288,69.5128,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19661,283.7699,3734.6946,75.0128,180.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19682,286.5965,3701.8474,69.5128,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19681,237.4409,3645.8386,69.5129,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19649,262.0187,3673.8430,69.5129,0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19649,235.0180,3608.6575,69.5129,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19649,235.0180,3558.6575,69.5129,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19682,232.5950,3521.4763,69.5129,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19649,130.2005,3429.9766,59.7885,0.0000,-15.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19682,208.2971,3497.1785,69.5129,0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19649,171.1159,3494.7554,69.5129,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19646,222.1594,3507.6140,69.5129,0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19662,135.4500,3489.5059,69.5129,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19684,130.2004,3466.3757,68.6959,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19670,258.4832,3670.3076,19.4881,0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19686,108.0004,3345.2810,37.9402,0.0000,0.0000,-90.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19649,119.1004,3381.6802,46.8476,0.0000,-15.0000,90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "BlueDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19668,113.5504,3349.2935,71.1235,0.0000,15.0000,-90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "BlueDirt1", 0);

	CreatePlayerObject(playerid,19663,108.0004,3257.8167,34.8733,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,130.2004,3473.6985,19.3535,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,108.0003,3332.8167,-12.9014,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,216.7155,3422.5000,35.9592,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19672,275.3560,3419.4604,50.1579,0.0000,0.0000,-36.0000,999.0);
	CreatePlayerObject(playerid,19672,281.1376,3401.6663,54.0688,0.0000,0.0000,72.0000,999.0);
	CreatePlayerObject(playerid,19672,266.0011,3390.6689,58.0268,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19672,250.8645,3401.6663,61.8254,0.0000,0.0000,-72.0000,999.0);
	CreatePlayerObject(playerid,19672,256.6462,3419.4604,65.9731,0.0000,0.0000,-144.0000,999.0);
	CreatePlayerObject(playerid,19672,256.6462,3419.4604,85.7634,0.0000,0.0000,-144.0000,999.0);
	CreatePlayerObject(playerid,19672,275.3560,3419.4604,69.9482,0.0000,0.0000,-36.0000,999.0);
	CreatePlayerObject(playerid,19672,281.1376,3401.6663,73.8591,0.0000,0.0000,72.0000,999.0);
	CreatePlayerObject(playerid,19672,266.0011,3390.6689,77.8171,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19672,250.8645,3401.6663,81.6157,0.0000,0.0000,-72.0000,999.0);
	CreatePlayerObject(playerid,19672,276.0011,3422.5000,88.0673,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19672,305.9753,3422.5000,88.0673,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19672,327.3069,3417.8904,87.9516,0.0000,0.0000,-45.0000,999.0);
	CreatePlayerObject(playerid,19550,7.5000,3710.0000,4.3077,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19672,331.9166,3366.5771,85.9599,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,331.9166,3316.5845,85.9599,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,331.9166,3346.5918,85.9599,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,331.9166,3266.5923,85.9599,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,331.9166,3296.5999,85.9599,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,327.3070,3245.2786,88.2336,0.0000,0.0000,-135.0000,999.0);
	CreatePlayerObject(playerid,19672,304.6953,3245.2788,88.1757,0.0000,0.0000,135.0000,999.0);
	CreatePlayerObject(playerid,19672,297.0461,3285.9395,86.1250,0.0000,0.0000,126.0000,999.0);
	CreatePlayerObject(playerid,19672,279.2520,3291.7209,82.0771,0.0000,0.0000,16.0000,999.0);
	CreatePlayerObject(playerid,19672,268.2546,3276.5845,78.2285,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,279.2520,3261.4480,73.9912,0.0000,0.0000,-20.0000,999.0);
	CreatePlayerObject(playerid,19672,297.0460,3267.2297,70.2106,0.0000,0.0000,54.0000,999.0);
	CreatePlayerObject(playerid,19672,300.0856,3286.5845,68.0976,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,300.0856,3316.5479,68.0976,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,300.0001,3336.5508,68.3325,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,300.0001,3366.5588,68.3325,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,300.0001,3386.5305,68.3325,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,300.0001,3416.5354,68.3325,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,311.1857,3436.5845,68.1464,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,311.1857,3466.5889,68.1464,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,311.1857,3486.5654,68.1464,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,311.1857,3516.5720,68.1464,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,311.1857,3531.8862,91.8754,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,311.1857,3560.2422,91.8754,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,311.1857,3590.2336,91.8754,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,311.1858,3610.2466,89.8444,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,311.1858,3640.2439,89.8444,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,315.7955,3661.5525,91.7584,0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19540,85.0000,3257.5000,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19540,-210.0000,3165.0000,4.3077,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19540,-210.0000,3710.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,338.4071,3670.7717,91.8683,0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19672,346.0564,3691.4324,93.9506,0.0000,0.0000,54.0000,999.0);
	CreatePlayerObject(playerid,19672,363.8504,3697.2141,97.8625,0.0000,0.0000,-18.0000,999.0);
	CreatePlayerObject(playerid,19672,374.8478,3682.0776,101.8288,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,363.8505,3666.9409,105.8737,0.0000,0.0000,18.0000,999.0);
	CreatePlayerObject(playerid,19672,346.0564,3672.7227,109.8370,0.0000,0.0000,-54.0000,999.0);
	CreatePlayerObject(playerid,19672,346.0564,3672.7227,129.7860,0.0000,0.0000,-54.0000,999.0);
	CreatePlayerObject(playerid,19672,363.8505,3666.9409,125.8226,0.0000,0.0000,18.0000,999.0);
	CreatePlayerObject(playerid,19672,374.8478,3682.0776,121.7777,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,363.8504,3697.2141,117.8115,0.0000,0.0000,-18.0000,999.0);
	CreatePlayerObject(playerid,19672,346.0564,3691.4324,113.8996,0.0000,0.0000,54.0000,999.0);
	CreatePlayerObject(playerid,19672,338.4071,3693.3833,131.7450,0.0000,0.0000,-45.0000,999.0);
	CreatePlayerObject(playerid,19672,311.7588,3697.9929,130.6222,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,287.1232,3697.9929,123.3002,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,269.3201,3697.9929,113.6222,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,243.3627,3697.9929,98.6212,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,226.0258,3697.9929,88.6012,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,200.0598,3697.9929,73.6839,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,178.2511,3697.9929,62.4286,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,154.6358,3697.9929,56.6647,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,35.0058,3697.9932,34.0287,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,5.0128,3697.9932,34.0287,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,5.0128,3666.1621,34.0287,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,35.0058,3666.1621,34.0287,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,55.0236,3666.1621,36.0365,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,85.0416,3666.1621,36.0365,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,105.0083,3666.1621,34.0287,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,134.9800,3666.1621,34.0287,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4567,3669.6313,34.0726,0.0000,0.0000,27.0000,999.0);
	CreatePlayerObject(playerid,19672,174.5848,3682.5562,34.1170,0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19672,195.7980,3703.7695,34.1170,0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19672,215.5406,3718.6057,33.9744,0.0000,0.0000,18.0000,999.0);
	CreatePlayerObject(playerid,19672,234.7318,3717.1240,34.0809,0.0000,0.0000,-36.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3694.2480,36.0042,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3664.2678,36.0042,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3504.2703,36.0042,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3474.2324,36.0042,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3434.2769,32.0711,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3404.2515,32.0711,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3384.2493,36.0140,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3354.2383,36.0140,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3334.2317,32.0321,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3304.2390,31.9984,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,215.3770,3278.3325,33.8870,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,185.3680,3278.3325,33.8870,0.0000,0.0000,-0.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,175.3770,3294.2480,64.8538,180.0000,0.0000,-180.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	TempObjectNumber = CreatePlayerObject(playerid,19652,175.3769,3294.2480,84.8538,180.0000,0.0000,-180.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "GreenDirt1", 0);

	CreatePlayerObject(playerid,19672,159.4614,3304.2480,114.0335,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,164.0711,3282.9424,113.9617,0.0000,0.0000,-45.0000,999.0);
	CreatePlayerObject(playerid,19672,184.7318,3281.3721,112.0262,0.0000,0.0000,36.0000,999.0);
	CreatePlayerObject(playerid,19672,190.5135,3299.1663,107.8524,0.0000,0.0000,-72.0000,999.0);
	CreatePlayerObject(playerid,19672,175.3769,3310.1636,103.8580,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,160.2404,3299.1663,100.0933,0.0000,0.0000,72.0000,999.0);
	CreatePlayerObject(playerid,19672,166.0220,3281.3721,95.9705,0.0000,0.0000,-36.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4614,3334.2378,114.0335,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4614,3354.2266,114.0335,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4614,3384.2668,114.0335,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4614,3412.5928,114.0335,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4614,3486.2449,90.4535,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4614,3559.9297,66.7921,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4614,3579.7673,44.2265,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4615,3427.9221,90.4296,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4615,3457.8840,90.4296,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4613,3620.2524,60.4987,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4613,3646.2703,75.5153,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4613,3668.8413,87.1338,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4613,3693.7808,93.1308,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,190.6684,3739.9441,92.3369,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19672,210.4541,3739.9441,87.6401,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19672,239.4345,3739.9441,79.8874,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19672,263.4093,3739.9441,74.7607,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19672,285.5501,3699.5776,74.1313,-0.0000,0.0000,63.0000,999.0);
	CreatePlayerObject(playerid,19672,272.6253,3684.4497,74.1723,-0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19672,251.4121,3663.2366,74.1261,-0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19672,236.5759,3643.4939,74.1149,-0.0000,0.0000,72.0000,999.0);
	CreatePlayerObject(playerid,19672,235.0180,3623.6575,74.2145,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,235.0180,3593.5452,74.2145,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,235.0180,3573.5925,74.2145,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,235.0180,3543.6985,74.2145,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,231.5486,3519.2065,74.1295,-0.0000,0.0000,63.0000,999.0);
	CreatePlayerObject(playerid,19672,205.9522,3496.3135,74.1754,-0.0000,0.0000,18.0000,999.0);
	CreatePlayerObject(playerid,19672,186.1409,3494.8167,74.1754,-0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,156.0972,3494.8167,74.1754,-0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,134.8101,3490.1458,74.2067,-0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19672,130.2005,3463.4688,72.9750,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,130.2005,3443.7839,68.1349,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,130.2005,3414.7671,60.4308,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,129.9005,3396.0225,56.9608,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,119.1004,3395.4226,55.3437,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,119.1004,3366.4854,47.5958,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,118.8004,3347.7910,44.0340,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,108.0004,3342.5022,42.2326,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,108.0004,3272.8323,39.8413,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,108.0004,3242.8140,39.7832,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19649,241.2924,3629.2480,29.3538,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19649,241.2925,3539.2480,29.3539,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19642,241.2924,3589.2480,29.3539,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19642,241.2924,3579.2480,29.3539,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,241.7848,3542.6001,-22.0166,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,241.2924,3624.2480,-20.6709,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3524.2693,34.0474,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3554.2651,34.0474,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3614.2158,34.0474,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,241.2924,3644.2666,34.0474,0.0000,0.0000,-90.0000,999.0);

	TempObjectNumber = CreatePlayerObject(playerid,19649,159.4614,3516.5723,62.0340,0.0000,-0.0000,-90.0000,999.0);
	SetPlayerObjectMaterial(playerid, TempObjectNumber, 0, 19659, "MatTubes", "YellowDirt1", 0);

	CreatePlayerObject(playerid,19672,159.4615,3501.5842,66.7697,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19672,159.4615,3531.5461,66.7697,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19685,159.4614,3577.6987,39.1911,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19685,159.4614,3601.7781,45.6431,0.0000,15.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19646,159.4614,3709.0286,88.9614,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19646,159.4614,3719.0286,88.9614,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19670,235.0180,3533.6575,19.4881,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,235.0180,3613.6575,19.4881,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,159.4614,3447.9102,35.6692,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,159.4614,3521.5723,12.0093,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,159.4614,3570.0881,-11.5234,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19661,164.7110,3734.6946,94.4614,-180.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19670,316.0011,3240.6689,33.4567,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19550,272.4998,3570.0000,4.3080,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19550,147.4997,3570.0000,4.3080,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19550,272.4998,3445.0000,4.3080,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19550,272.4998,3320.0000,4.3080,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19549,85.0002,3273.7500,4.3077,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19542,334.9997,3445.0000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19542,334.9997,3320.0000,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19550,147.4997,3445.0000,4.3080,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19550,147.4997,3320.0000,4.3080,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,762,159.2296,3364.1545,8.0631,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,621,172.3828,3530.9956,4.1185,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,621,210.9594,3632.0981,4.1185,0.0000,0.0000,-81.0000,999.0);
	CreatePlayerObject(playerid,621,216.5798,3372.2180,4.1185,0.0000,0.0000,-55.0000,999.0);
	CreatePlayerObject(playerid,621,169.0373,3244.0442,4.1185,0.0000,0.0000,21.0000,999.0);
	CreatePlayerObject(playerid,621,348.5469,3253.4072,4.1185,0.0000,0.0000,71.0000,999.0);
	CreatePlayerObject(playerid,762,159.7794,3569.8127,8.0631,0.0000,0.0000,40.0000,999.0);
	CreatePlayerObject(playerid,762,311.5156,3624.8386,8.0631,0.0000,0.0000,78.0000,999.0);
	CreatePlayerObject(playerid,762,298.8590,3306.5583,8.0631,0.0000,0.0000,126.0000,999.0);
	CreatePlayerObject(playerid,762,24.2674,3664.7112,8.0631,0.0000,0.0000,169.0000,999.0);
	CreatePlayerObject(playerid,762,159.5200,3713.7891,8.0631,0.0000,0.0000,-140.0000,999.0);
	CreatePlayerObject(playerid,762,290.4150,3422.7559,8.0631,0.0000,0.0000,-175.0000,999.0);
	CreatePlayerObject(playerid,762,240.0694,3678.5208,8.0631,0.0000,0.0000,122.0000,999.0);
	CreatePlayerObject(playerid,762,107.5217,3293.8779,9.0631,0.0000,0.0000,50.0000,999.0);
	CreatePlayerObject(playerid,621,60.2490,3681.9932,4.1185,0.0000,0.0000,36.0000,999.0);
	CreatePlayerObject(playerid,621,313.2220,3679.3630,4.1185,0.0000,0.0000,82.0000,999.0);
	CreatePlayerObject(playerid,621,267.0584,3501.8621,4.1185,0.0000,0.0000,27.0000,999.0);
	CreatePlayerObject(playerid,621,263.6267,3280.8892,4.1185,0.0000,0.0000,-52.0000,999.0);
	CreatePlayerObject(playerid,621,318.7102,3387.3503,4.1185,0.0000,0.0000,42.0000,999.0);
	CreatePlayerObject(playerid,621,131.9952,3640.5090,4.1185,0.0000,0.0000,121.0000,999.0);
	CreatePlayerObject(playerid,3509,87.8005,3438.1350,4.1266,0.0000,0.0000,-45.0000,999.0);
	CreatePlayerObject(playerid,3509,87.8005,3407.0583,4.1266,0.0000,0.0000,62.0000,999.0);
	CreatePlayerObject(playerid,19649,108.0004,3307.8167,37.1233,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19684,139.8314,3245.2810,36.3063,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19649,139.8315,3281.6802,27.3989,0.0000,-15.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19686,139.8315,3318.0793,18.4916,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19661,145.0810,3451.2097,17.6746,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19649,139.8315,3355.5437,17.6746,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19649,139.8315,3405.5437,17.6746,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19646,139.8315,3435.5437,17.6746,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19649,180.7469,3456.4592,17.6746,0.0000,0.0000,180.0000,999.0);
	CreatePlayerObject(playerid,19662,216.4129,3461.7087,17.6746,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19662,216.4129,3493.0408,17.6746,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19646,221.6624,3477.3748,17.6746,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19649,170.8531,3498.2903,14.6323,0.0000,-5.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19648,130.4799,3498.2903,11.5691,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,19642,120.4800,3498.2903,11.5691,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19650,93.7424,3498.2903,6.9995,0.0000,-19.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19534,77.5000,3500.0000,4.3077,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,3509,87.8005,3513.5872,4.1266,0.0000,0.0000,-45.0000,999.0);
	CreatePlayerObject(playerid,3509,87.8005,3482.5103,4.1266,0.0000,0.0000,62.0000,999.0);
	CreatePlayerObject(playerid,19672,108.0004,3322.8167,41.8230,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,108.0004,3292.8167,41.8230,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,112.6100,3221.5107,41.8151,0.0000,0.0000,135.0000,999.0);
	CreatePlayerObject(playerid,19672,135.2216,3221.5107,41.8151,0.0000,0.0000,-135.0000,999.0);
	CreatePlayerObject(playerid,19672,139.8314,3244.9832,40.9682,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,139.8314,3267.9055,35.9077,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,139.8314,3296.8618,28.1914,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,139.8314,3317.8293,23.2563,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,139.8314,3340.5437,22.4207,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,139.8314,3370.5759,22.4207,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,139.8314,3390.5437,22.4207,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,139.8314,3420.5437,22.4207,-0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19672,144.4411,3451.8496,22.4207,-0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19672,165.7469,3456.4592,22.4207,-0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,195.7418,3456.4592,22.4207,-0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,217.0527,3461.0688,22.4207,-0.0000,0.0000,45.0000,999.0);
	CreatePlayerObject(playerid,19672,217.0528,3493.6804,22.4207,-0.0000,0.0000,-45.0000,999.0);
	CreatePlayerObject(playerid,19672,185.5585,3498.2903,20.4852,-0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19672,155.6512,3498.2903,17.9867,-0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19670,108.0004,3257.8167,-17.4014,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,139.8314,3232.8167,-12.9015,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,139.8315,3330.5437,-32.3501,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,139.8315,3410.5437,-32.3501,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19670,185.7469,3456.4592,-32.3501,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19670,175.5944,3498.2903,-34.9671,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19659,123.9158,3222.1506,37.1233,0.0000,0.0000,90.0000,999.0);
	CreatePlayerObject(playerid,19542,147.4997,3257.5000,4.3080,0.0000,0.0000,-90.0000,999.0);
	CreatePlayerObject(playerid,19543,77.5002,3383.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19536,7.5000,3461.2500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19536,7.5000,3803.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,19550,147.4997,3695.0000,4.3080,0.0000,0.0000,-0.0000,999.0);
	CreatePlayerObject(playerid,19550,272.4998,3695.0000,4.3080,0.0000,0.0000,-180.0000,999.0);
	CreatePlayerObject(playerid,621,236.0952,3742.8730,4.1185,0.0000,0.0000,125.0000,999.0);
	CreatePlayerObject(playerid,19536,7.5000,3383.7500,4.3077,0.0000,0.0000,0.0000,999.0);
	CreatePlayerObject(playerid,16146, 62.93165, 3406.10645, 7.50091,   0.00000, 0.00000, -90.35997);
	CreatePlayerObject(playerid,2232, 52.27252, 3414.25098, 4.97579,   0.00000, 0.00000, -148.80043);
    CreatePlayerObject(playerid,8040, 2.34296, 3374.59326, 5.29753,   0.00000, 0.00000, 90.0);
    
	// Exit here
	return 1;
}

CreateCarShop() {    
    for (new i = 0; i < CARS_NUMBER; ++i) {
        carCost[shopCarIds[i]] = shopCarCost[i];
        carName[shopCarIds[i]] = shopCarNames[i];
    }
    
    /*new vehicle_id = AddStaticVehicleEx(541, 17.6, 3405.3, 5.3, 90.0, -1, -1, 0);
    SetVehicleParamsEx(vehicle_id, 1, 1, 0, 1, 1, 1, 1);
    new vehicle3Dtext = Create3DTextLabel( "Bullet", 0xFF0000AA, 0.0, 0.0, 0.0, 150.0, 0, 1 );
    Attach3DTextLabelToVehicle( vehicle3Dtext, vehicle_id, 0.0, 2.0, 2.0);
    vehicle3Dtext = Create3DTextLabel( "$2,125", 0xFFF033AA, 0.0, 0.0, 0.0, 120.0, 0, 1 );
    Attach3DTextLabelToVehicle( vehicle3Dtext, vehicle_id, 0.0, 2.0, 1.8);*/
    
    new vehicle_id = AddStaticVehicleEx(551, 16.4, 3405.3, 5.3, 90.0, -1, -1, 0);
    SetVehicleParamsEx(vehicle_id, 1, 1, 0, 1, 1, 1, 1);
    new i = 0;
    new vehicle3Dtext = Create3DTextLabel(shopCarNames[i++], 0xFF0000AA, 0.0, 0.0, 0.0, 150.0, 0, 1 );
    Attach3DTextLabelToVehicle( vehicle3Dtext, vehicle_id, 0.0, 2.0, 2.0);
    vehicle3Dtext = Create3DTextLabel( "$875", 0xFFF033AA, 0.0, 0.0, 0.0, 120.0, 0, 1 );
    Attach3DTextLabelToVehicle( vehicle3Dtext, vehicle_id, 0.0, 2.0, 1.8);

    vehicle_id = AddStaticVehicleEx(521, 17.6, 3399, 5.3, 90.0, -1, -1, 0);
    SetVehicleParamsEx(vehicle_id, 1, 1, 0, 1, 1, 1, 1);
    vehicle3Dtext = Create3DTextLabel( shopCarNames[i++], 0xFFF033AA, 0.0, 0.0, 0.0, 150.0, 0, 1 );
    Attach3DTextLabelToVehicle( vehicle3Dtext, vehicle_id, 0.0, 2.0, 2.0);
    vehicle3Dtext = Create3DTextLabel( "$1250", 0xFFF033AA, 0.0, 0.0, 0.0, 120.0, 0, 1 );
    Attach3DTextLabelToVehicle( vehicle3Dtext, vehicle_id, 0.0, 2.0, 1.8);
    
    vehicle_id = AddStaticVehicleEx(500, 17.6, 3392.4856, 5.3, 90.0, -1, -1, 0);
    SetVehicleParamsEx(vehicle_id, 1, 1, 0, 1, 1, 1, 1);
    vehicle3Dtext = Create3DTextLabel( shopCarNames[i++], 0xA3F0F3AA, 0.0, 0.0, 0.0, 150.0, 0, 1 );
    Attach3DTextLabelToVehicle( vehicle3Dtext, vehicle_id, 0.0, 2.0, 2.0);
    vehicle3Dtext = Create3DTextLabel( "$625", 0xFFF033AA, 0.0, 0.0, 0.0, 120.0, 0, 1 );
    Attach3DTextLabelToVehicle( vehicle3Dtext, vehicle_id, 0.0, 2.0, 1.8);
    
    vehicle_id = AddStaticVehicleEx(581, 17.6, 3385.7856, 5.3, 90.0, -1, -1, 0);
    SetVehicleParamsEx(vehicle_id, 1, 1, 0, 1, 1, 1, 1);
    vehicle3Dtext = Create3DTextLabel( shopCarNames[i++], 0xFFF0F3AA, 0.0, 0.0, 0.0, 150.0, 0, 1 );
    Attach3DTextLabelToVehicle( vehicle3Dtext, vehicle_id, 0.0, 2.0, 2.0);
    vehicle3Dtext = Create3DTextLabel( "$250", 0xFFF033AA, 0.0, 0.0, 0.0, 120.0, 0, 1 );
    Attach3DTextLabelToVehicle( vehicle3Dtext, vehicle_id, 0.0, 2.0, 1.8);
    
    carShopPickup = CreatePickup(1274, 23, 1.54296, 3414, 5.29753);
    garagePickup = CreatePickup(19320, 23, 2.54296, 3414, 5.29753);
    Create3DTextLabel("Покупка и аренда машин", 0x008080FF, 1.54296, 3414, 5.29753, 40.0, 0, false);
    Create3DTextLabel("Гараж", 0x008080FF, 2.54296, 3414, 5.29753, 40.0, 0, false);

	carShopMenu = CreateMenu("Cars",1, 50.0, 200.0, 120.0, 250.0);
    AddMenuItem(carShopMenu,0,"Buy");
    AddMenuItem(carShopMenu,0,"Rent");
	garageMenu = CreateMenu("Cars",1, 50.0, 200.0, 120.0, 250.0);
    AddMenuItem(garageMenu,0,"Owned");
    AddMenuItem(garageMenu,0,"Rented");
    AddMenuItem(garageMenu,0,"Repair");
}

AddPlayersToRace(num)
{
	new pos;
	new Float:distance;
	gGrid2Count=0;
	
    // Подсчёт готовых игроков
    gTotalRacers = 0;
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && gPlayerData[i][pReady])
        {
            gTotalRacers++;
        }

        // Скрыть интерфейс у всех
        TextDrawHideForPlayer(i, Ttime);
        TextDrawHideForPlayer(i, Tappend[i]);
        TextDrawHideForPlayer(i, Tposition[i]);
        TextDrawHideForPlayer(i, Ttotalracers);
        UpdatePlayerRankHUD(i);
        TextDrawHideForPlayer(i, TRankHUD[i]);
    	TextDrawShowForPlayer(i, TRankHUD[i]);
    }
    new tmp[5];
    format(tmp, sizeof(tmp), "/%d", gTotalRacers);
    TextDrawSetString(Ttotalracers, tmp);
    // Показать интерфейс только у ready игроков
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && gPlayerData[i][pReady])
        {
            TextDrawShowForPlayer(i, Ttime);
            TextDrawShowForPlayer(i, Tappend[i]);
            TextDrawShowForPlayer(i, Tposition[i]);
            TextDrawShowForPlayer(i, Ttotalracers);
        }
    }
    
	for(new i=num-1;i>-1;i--)
	{
		new j = gScores2[i][0];
		if (IsPlayerConnected(j) && gGrided[j]==0 && xRaceBuilding[j]==0 && spawned[j]==1 && gPlayerData[j][pReady])
		{
			gPlayerData[j][pIngame] = 1;
			if (gGrid2Count>1)
			{
				distance=10.0;
				switch (gGrid2Index)
				{
				    case 0:
				    {
						gGrid2[0] -= (distance * floatsin(-gGrid2[3], degrees));
						gGrid2[1] -= (distance * floatcos(-gGrid2[3], degrees));
						SetPlayerVirtualWorld(j, gWorldID);
						SetPlayerPos(j,gGrid2[0]+2.0,gGrid2[1],gGrid2[2]+2.0);
						gGrid2Index=1;

				    }
				    case 1:
				    {
						gGrid2[4] -= (distance * floatsin(-gGrid2[7], degrees));
						gGrid2[5] -= (distance * floatcos(-gGrid2[7], degrees));
						SetPlayerVirtualWorld(j, gWorldID);
						SetPlayerPos(j,gGrid2[4]+2.0,gGrid2[5],gGrid2[6]+2.0);
						gGrid2Index=0;
				    }
				}
			} else {
				distance=10.0;
				switch (gGrid2Index)
				{
				    case 0:
				    {
				        SetPlayerVirtualWorld(j, gWorldID);
						SetPlayerPos(j,gGrid2[0]+2.0,gGrid2[1],gGrid2[2]+2.0);
						gGrid2Index=1;

				    }
				    case 1:
				    {
				        SetPlayerVirtualWorld(j, gWorldID);
						SetPlayerPos(j,gGrid2[4]+2.0,gGrid2[5],gGrid2[6]+2.0);
						gGrid2Index=0;
				    }
				}
			}
			gGrid2Count++;
			pos++;
			//TogglePlayerControllable(j,0);
		}
	}
}

public AddRacers(num)
{
	new pos;
	new Float:distance;
	gGridCount=0;
	for(new i=num-1;i>-1;i--)
	{
		new j = gScores2[i][0];
		if (IsPlayerConnected(j) && gGrided[j]==0 && xRaceBuilding[j]==0 && spawned[j]==1 && gPlayerData[j][pReady])
		{
			//printf("DEBUG AddRacers %d %d", gGrided[j], gPlayerData[j][pReady]);
			if (gGridCount>1)
			{
				distance=10.0;
				switch (gGridIndex)
				{
				    case 0:
				    {
						gGrid[0] -= (distance * floatsin(-gGrid[3], degrees));
						gGrid[1] -= (distance * floatcos(-gGrid[3], degrees));
						//vehicles[gGridCount] = CreateVehicle(gCarModelID,gGrid[0],gGrid[1],gGrid[2],gGrid[3],-1,-1,10);
						vehicles[gGridCount] = CreateVehicle(CurrentCar(j),gGrid[0],gGrid[1],gGrid[2],gGrid[3],CurrentColor(j),-1,10);
						SetVehicleVirtualWorld(vehicles[gGridCount],gWorldID);
						printf("Created car, Count:%d",gGridCount);
						//SetPlayerPos(j,gGrid[0],gGrid[1],gGrid[2]+5.0);
						gGridIndex=1;

				    }
				    case 1:
				    {
						gGrid[4] -= (distance * floatsin(-gGrid[7], degrees));
						gGrid[5] -= (distance * floatcos(-gGrid[7], degrees));
						//vehicles[gGridCount] = CreateVehicle(gCarModelID,gGrid[4],gGrid[5],gGrid[6],gGrid[7],-1,-1,10);
						vehicles[gGridCount] = CreateVehicle(CurrentCar(j),gGrid[4],gGrid[5],gGrid[6],gGrid[7],CurrentColor(j),-1,10);
						SetVehicleVirtualWorld(vehicles[gGridCount],gWorldID);
						printf("Created car, Count:%d",gGridCount);
						//SetPlayerPos(j,gGrid[4],gGrid[5],gGrid[6]+5.0);
						gGridIndex=0;
				    }
				}
			} else {
				distance=10.0;
				switch (gGridIndex)
				{
				    case 0:
				    {
						//vehicles[gGridCount] = CreateVehicle(gCarModelID,gGrid[0],gGrid[1],gGrid[2],gGrid[3],-1,-1,10);
						vehicles[gGridCount] = CreateVehicle(CurrentCar(j),gGrid[0],gGrid[1],gGrid[2],gGrid[3],CurrentColor(j),-1,10);
						SetVehicleVirtualWorld(vehicles[gGridCount],gWorldID);
						printf("Created car, Count:%d",gGridCount);
						//SetPlayerPos(j,gGrid[0],gGrid[1],gGrid[2]+5.0);
						gGridIndex=1;

				    }
				    case 1:
				    {
						//vehicles[gGridCount] = CreateVehicle(gCarModelID,gGrid[4],gGrid[5],gGrid[6],gGrid[7],-1,-1,10);
						vehicles[gGridCount] = CreateVehicle(CurrentCar(j),gGrid[4],gGrid[5],gGrid[6],gGrid[7],CurrentColor(j),-1,10);
						SetVehicleVirtualWorld(vehicles[gGridCount],gWorldID);
						printf("Created car, Count:%d",gGridCount);
						//SetPlayerPos(j,gGrid[4],gGrid[5],gGrid[6]+5.0);
						gGridIndex=0;
				    }
				}
			}
			processCarProperty(j, vehicles[gGridCount]);
			gGridCount++;
			SetRaceText(j,pos+1);
			SetTimerEx("PutPlayerInVehicleTimed",TIME_PUT_PLAYER,0,"ddd",j, vehicles[pos],0);
			printf("Помещаю %d в машину %d через 3 сек..",j,pos);
			SetCheckpoint(j,gPlayerProgress[j],gMaxCheckpoints);
			gGrided[j]=1;
			pos++;
		}
	}
}

SetRaceText(playerid, pos)
{

	//HideAllRaceText(playerid);
	new append[5];
	switch (pos)
	{
		case 1,21,31,41,51,61,71,81,91:	format(append, sizeof(append), "ST");
		case 2,22,32,42,52,62,72,82,92:	format(append, sizeof(append), "ND");
		case 3,23,33,43,53,63,73,83,93: format(append, sizeof(append), "RD");
		default: format(append, sizeof(append), "TH");
	}
	new tmp[5];
	format(tmp,5,"%d", pos);
	TextDrawSetString(Tposition[playerid],tmp);
	TextDrawSetString(Tappend[playerid],append);

	return 1;
}


public GridSetupPlayer(playerid)
{	//Staggered Grid Modified from Y_Less's GetXYInFrontOfPlayer() function

	new Float:distance;
	
	if (gGrid2Count>1)
	{
		distance=10.0;
		switch (gGrid2Index)
		{
		    case 0:
		    {
				gGrid2[0] -= (distance * floatsin(-gGrid2[3], degrees));
				gGrid2[1] -= (distance * floatcos(-gGrid2[3], degrees));

		    }
		    case 1:
		    {
				gGrid2[4] -= (distance * floatsin(-gGrid2[7], degrees));
				gGrid2[5] -= (distance * floatcos(-gGrid2[7], degrees));
		    }
		}
	}

	switch (gGrid2Index)
	{
	    case 0:
	    {
	        SetPlayerVirtualWorld(playerid, gWorldID);
			SetPlayerPos(playerid,gGrid2[0],gGrid2[1],gGrid2[2]+1.0);
			//vehicles[gGridCount] = CreateVehicle(gCarModelID,gGrid[0],gGrid[1],gGrid[2],gGrid[3],-1,-1,10);
			//SetVehiclePos(vehicles[playerid],gGrid[0],gGrid[1],gGrid[2]);
			//SetVehicleZAngle(vehicles[playerid],gGrid[3]);
			gGridIndex=1;
		}
	    case 1:
	    {
	        SetPlayerVirtualWorld(playerid, gWorldID);
			SetPlayerPos(playerid,gGrid2[4],gGrid2[5],gGrid2[6]+1.0);
			//vehicles[gGridCount] = CreateVehicle(gCarModelID,gGrid[4],gGrid[5],gGrid[6],gGrid[7],-1,-1,10);
			//SetVehiclePos(vehicles[playerid],gGrid[4],gGrid[5],gGrid[6]);
			//SetVehicleZAngle(vehicles[playerid],gGrid[7]);
			gGridIndex=0;
	    }


	}
	//SetRaceText(playerid,gGridCount+1);
	//PutPlayerInVehicle(playerid,vehicles[gGridCount],0);
	//SetTimerEx("PutPlayerInVehicleTimed",3000,0,"ddd",playerid, vehicles[gGridCount],0);
	//SetCameraBehindPlayer(playerid);
//	if(gRaceStarted==0)TogglePlayerControllable(playerid,false);
	gGrid2Count++;
	//SetCheckpoint(playerid,gPlayerProgress[playerid],gMaxCheckpoints);
	//printf("GridSetupDebug- time:%d gridpos:%d playerid:%d vehicle:%d",GetTickCount(),gGridCount,playerid,vehicles[gGridCount]);
	return 1;
}

public PullMoney(playerid)
{
	gPlayerData[playerid][pMoney] = GetPlayerMoney(playerid);
	SavePlayerData(playerid);
}

public GridSetup(playerid)
{	//Staggered Grid Modified from Y_Less's GetXYInFrontOfPlayer() function
	new Float:distance;
	if (gGridCount>1)
	{
		distance=10.0;
		switch (gGridIndex)
		{
		    case 0:
		    {
				gGrid[0] -= (distance * floatsin(-gGrid[3], degrees));
				gGrid[1] -= (distance * floatcos(-gGrid[3], degrees));

		    }
		    case 1:
		    {
				gGrid[4] -= (distance * floatsin(-gGrid[7], degrees));
				gGrid[5] -= (distance * floatcos(-gGrid[7], degrees));
		    }
		}
	}

	switch (gGridIndex)
	{
	    case 0:
	    {
			//SetPlayerPos(playerid,gGrid[0],gGrid[1],gGrid[2]+5.0);
			//vehicles[gGridCount] = CreateVehicle(gCarModelID,gGrid[0],gGrid[1],gGrid[2],gGrid[3],-1,-1,10);
			vehicles[gGridCount] = CreateVehicle(CurrentCar(playerid),gGrid[0],gGrid[1],gGrid[2],gGrid[3],CurrentColor(playerid),-1,10);
			SetVehicleVirtualWorld(vehicles[gGridCount],gWorldID);
			//SetVehiclePos(vehicles[playerid],gGrid[0],gGrid[1],gGrid[2]);
			//SetVehicleZAngle(vehicles[playerid],gGrid[3]);
			gGridIndex=1;
		}
	    case 1:
	    {

			//SetPlayerPos(playerid,gGrid[4],gGrid[5],gGrid[6]+5.0);
			//vehicles[gGridCount] = CreateVehicle(gCarModelID,gGrid[4],gGrid[5],gGrid[6],gGrid[7],-1,-1,10);
			vehicles[gGridCount] = CreateVehicle(CurrentCar(playerid),gGrid[4],gGrid[5],gGrid[6],gGrid[7],CurrentColor(playerid),-1,10);
			SetVehicleVirtualWorld(vehicles[gGridCount],gWorldID);
			//SetVehiclePos(vehicles[playerid],gGrid[4],gGrid[5],gGrid[6]);
			//SetVehicleZAngle(vehicles[playerid],gGrid[7]);
			gGridIndex=0;
	    }


	}
	SetRaceText(playerid,gGridCount+1);
	//PutPlayerInVehicle(playerid,vehicles[gGridCount],0);
	SetTimerEx("PutPlayerInVehicleTimed",TIME_PUT_PLAYER,0,"ddd",playerid, vehicles[gGridCount],0);
	SetCameraBehindPlayer(playerid);
	if(gRaceStarted==0)TogglePlayerControllable(playerid,false);
    processCarProperty(playerid, vehicles[gGridCount]);
	gGridCount++;
	SetCheckpoint(playerid,gPlayerProgress[playerid],gMaxCheckpoints);
	gGrided[playerid] = 1;
	printf("GridSetupDebug- time:%d gridpos:%d playerid:%d vehicle:%d",GetTickCount(),gGridCount,playerid,vehicles[gGridCount]);
	return 1;
}

CurrentCar(playerid) {
    new c = gPlayerData[playerid][pCurrentCar];
    if (c < 0 || gPlayerData[playerid][pCurrentRent] == 0 && gPlayerData[playerid][pBoughtCarsHealth][c] < 25
              || gPlayerData[playerid][pCurrentRent] == 1 && gPlayerData[playerid][pRentedCarRaces][c] == 0) {
        SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Отсутствуют доступные транспортные средства.");
        SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Купите или арендуйте транспортное средство в /shop, затем выберите его в меню /garage, либо выполните ремонт в меню /garage.");
        SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Переключение на стандартную бесплатную машину...");
        return 404;
    } else if (gPlayerData[playerid][pCurrentRent] == 0 && gPlayerData[playerid][pBoughtCarsHealth][c] < 44) {
        SendClientMessage(playerid,COLOR_TEMP,"[ИНФО] У транспортного средства заканчивается здоровье.");
        SendClientMessage(playerid,COLOR_TEMP,"[ИНФО] Купите или арендуйте транспортное средство в /shop, затем выберите его в меню /garage, либо выполните ремонт в меню /garage.");
    } else if (gPlayerData[playerid][pCurrentRent] == 1 && gPlayerData[playerid][pRentedCarRaces][c] < 2)
        SendClientMessage(playerid,COLOR_TEMP,"[ИНФО] Заканчиваются арендованные транспортные средства. Купите или арендуйте транспортное средство в /shop, затем выберите его в меню /garage.");
    else {
        new maxRank = -1;
        new differentRanks = 0;
    
        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i)) {
                new rank = gPlayerData[i][pRank];
                if (maxRank != -1 && maxRank != rank)
                    differentRanks = 1;
                if (maxRank < rank)
                    rank = maxRank;
            }
            if (differentRanks == 1 && gPlayerData[playerid][pRank] != maxRank) {
                SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Выполняется уравнивание. Слишком хорошее транспортное средство, выберите другое.");
                SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Купите или арендуйте транспортное средство в /shop, затем выберите его в меню /garage, либо выполните ремонт в меню /garage.");
                SendClientMessage(playerid,COLOR_TEMP,"[ОШИБКА] Переключение на стандартную бесплатную машину...");
                return 404;
            }
        }
    }
    return shopCarIds[c];
}

CurrentColor(playerid) {
    new c = gPlayerData[playerid][pCurrentCar];
    if (c < 0)
        return -1;
    if (gPlayerData[playerid][pCurrentRent] == 0)
        return gPlayerData[playerid][pBoughtCarColor][c];
    return gPlayerData[playerid][pRentedCarColor][c];
}

stock ShowXPText(playerid, amount)
{
    if (TXP[playerid]) {
        TextDrawDestroy(TXP[playerid]);
        TXP[playerid] = Text:INVALID_TEXT_DRAW;
    }

    new text[32];
    format(text, sizeof(text), "~g~+%d XP", amount); // Зелёный цвет

    TXP[playerid] = TextDrawCreate(320.0, 180.0, text); // по центру
    TextDrawFont(TXP[playerid], 3);  // крупный шрифт
    TextDrawLetterSize(TXP[playerid], 1.0, 3.0);
    TextDrawColor(TXP[playerid], 0x00FF00FF); // ярко-зелёный
    TextDrawSetOutline(TXP[playerid], 2);
    TextDrawSetProportional(TXP[playerid], 1);

    TextDrawShowForPlayer(playerid, TXP[playerid]);

    SetTimerEx("HideXPText", 2000, false, "d", playerid);
}


LoadRaceList()
{
	new File:f;
	new line[256];
	if(fexist("racenames.txt"))
	{
		f = fopen("racenames.txt", io_read);
		while(fread(f,line,sizeof(line),false))
		{
     		new iidx;
			gRaceNames[gRaces] = strtok(line,iidx);
			new msg[256];
			format(msg,256,"%s.race",gRaceNames[gRaces]);
            if(fexist(msg))
			{
			} else {
				printf("Line%d - 404 %s",gRaces,gRaceNames[gRaces]);
			}
			gRaces++;
		}
		fclose(f);
	}
}

SaveRace(playerid)
{
	new msg[256];
	new trackname2[256];
	format(trackname2,256,"%s.txt",xRaceName[playerid]);
	new File:f2;
	f2 = fopen(trackname2, io_write);
	fclose(f2);
	
	new File:f3;
	f3 = fopen("buildlog.txt", io_append);
	new hour,mins,year,month,day;
	gettime(hour,mins);
	getdate(year,month,day);
	format(msg,256, "%d/%d/%d %d:%d - %s by %s\n",day,month,year,hour,mins,xRaceName[playerid],xCreatorName[playerid]);
	fwrite(f3,msg);
	fclose(f3);
	new trackname[256];
	format(trackname,256,"%s.race",xRaceName[playerid]);
	new File:f;
	f = fopen(trackname, io_write);
	format(msg,256, "15 %d %d %d %d %s\n",xTrackTime[playerid],xWorldTime[playerid],xWeatherID[playerid],xRaceType[playerid],xCreatorName[playerid]);
	fwrite(f,msg);
	if (xCarIds[playerid][0]<300)xCarIds[playerid][0]=565;
	format(msg,256, "%d\n",xCarIds[playerid][0]);
	fwrite(f,msg);
	format(msg,256, "%f %f %f %f\n",xRaceCheckpoints[playerid][0][0],xRaceCheckpoints[playerid][0][1],xRaceCheckpoints[playerid][0][2], xFacing[playerid]);
	fwrite(f,msg);
	format(msg,256, "%f %f %f %f\n",xRaceCheckpoints[playerid][1][0],xRaceCheckpoints[playerid][1][1],xRaceCheckpoints[playerid][1][2], xFacing[playerid]);
	fwrite(f,msg);
	new i=2;
	while (xRaceCheckpoints[playerid][i][2]>0)
	{
	    new msg2[256];
		format(msg2,256, "%f %f %f\n",xRaceCheckpoints[playerid][i][0],xRaceCheckpoints[playerid][i][1],xRaceCheckpoints[playerid][i][2]);
	    fwrite(f,msg2);
		i++;
	}
	
	fclose(f);
	new msgx[256];
	format(msgx,256,"Успешно! %s создана. Напиши /track %s для изменения",xRaceName[playerid], xRaceName[playerid]);
	SendClientMessage(playerid,COLOR_TEMP,msgx);
	printf("СОХРАНЕНО %s",xRaceName[playerid]);
	return 1;
}


LoadRace(racename[])
{
	printf("Загрузка трассы:%s",racename);
	new trackname[256];
	format (trackname,256,"%s.race",racename);
	if(!fexist(trackname))
	{
	    printf("404:трасса не найдена: %s",trackname);
	    LoadRace(gRaceNames[random(gRaces)]);
	    return 0;
	}
	format (gTrackName,256,"%s",racename);
	
	for(new i;i<MAX_RACECHECKPOINTS;i++)
	{
		RaceCheckpoints[i][0]=0.0;
		RaceCheckpoints[i][1]=0.0;
		RaceCheckpoints[i][2]=0.0;
		RaceCheckpoints[i][3]=0.0;
	}
	gMaxCheckpoints=0;
	new File:f;
	new line[256];
	f = fopen(trackname, io_read);
	fread(f,line,sizeof(line),false);
	new idx;
	gCountdown = strval(strtok(line,idx));
	gTrackTime = strval(strtok(line,idx));
	gWorldTime = strval(strtok(line,idx));
	gWeather = strval(strtok(line,idx));
	gRaceType = strval(strtok(line,idx));
	gRaceMaker = strtok(line,idx);

	fread(f,line,sizeof(line),false);
	new iiddxx;
	new gCars[5],j;
	gCars[0]=strval(strtok(line,iiddxx));
	gCars[1]=strval(strtok(line,iiddxx));
	gCars[2]=strval(strtok(line,iiddxx));
	gCars[3]=strval(strtok(line,iiddxx));
	gCars[4]=strval(strtok(line,iiddxx));

	for(new i=0;i<5;i++)
	{
	    if(gCars[i])
		{
			j=i;
		}
	}
	new rand;
	if (j) rand = random(j);
	else rand = j;
	gCarModelID=gCars[rand];

	fread(f,line,sizeof(line),false);
	iiddxx=0;
	gGrid[0]=floatstr(strtok(line,iiddxx));
	gGrid[1]=floatstr(strtok(line,iiddxx));
	gGrid[2]=floatstr(strtok(line,iiddxx));
	gGrid[3]=floatstr(strtok(line,iiddxx));
	gGrid2[0]=gGrid[0];
	gGrid2[1]=gGrid[1];
	gGrid2[2]=gGrid[2];
	gGrid2[3]=gGrid[3];

	fread(f,line,sizeof(line),false);
	iiddxx=0;
	gGrid[4]=floatstr(strtok(line,iiddxx));
	gGrid[5]=floatstr(strtok(line,iiddxx));
	gGrid[6]=floatstr(strtok(line,iiddxx));
	gGrid[7]=floatstr(strtok(line,iiddxx));
	gGrid2[4]=gGrid[4];
	gGrid2[5]=gGrid[5];
	gGrid2[6]=gGrid[6];
	
	while(fread(f,line,sizeof(line),false))
	{
		new idxx;
		RaceCheckpoints[gMaxCheckpoints][0] = floatstr(strtok(line,idxx));
		RaceCheckpoints[gMaxCheckpoints][1] = floatstr(strtok(line,idxx));
		RaceCheckpoints[gMaxCheckpoints][2] = floatstr(strtok(line,idxx));
		gMaxCheckpoints++;
	}
	fclose(f);

	for(new i;i<MAX_PLAYERS;i++)
	{
		gPlayerProgress[i]=0;
		PlaySoundForPlayer(i, 1186);
		if (i<100)RaceCheckpoints[i][3]=0;
		new Menu:Current;
		if (IsPlayerConnected(i) && GetPlayerMenu(i) == Current)
		{
			HideMenuForPlayer(voteMenu,i);
		}
	}
	gFinishOrder=0;
	gGridCount=0;
	gGrid2Count=0;
	KillTimer(gCountdowntimer);
	gCountdowntimer = SetTimer("Countdowntimer",1000,1);
	//SetWorldTime(gWorldTime);
	//SetWeather(gWeather);
	gRaceStart=0;
	gRaceStarted=0;
	gFinished=0;
	createVote();
	new tempTime[144];
	tempTime = HighScore(0);
	
	// Первое сообщение — заголовок трассы и автора
	format(gBestTime, sizeof(gBestTime),
		"{FFD700}<>{FFFFFF} Трасса: {FFD700}%s{FFFFFF} | Автор: {00FF00}%s{FFFFFF}",
		gTrackName, gRaceMaker);
	SendClientMessageToAll(-1, gBestTime);
	
	// Второе сообщение — рекорд
	SendClientMessageToAll(-1, tempTime);
	print("Гонка загружена");
	return 1;
}

SetCheckpoint(playerid, progress, totalchecks)
{
	new checktype;
	if(gRaceType==1)checktype=0; else if(gRaceType==2) checktype=4;
	if (progress==totalchecks-1)SetPlayerRaceCheckpoint(playerid,1,RaceCheckpoints[progress][0],RaceCheckpoints[progress][1],RaceCheckpoints[progress][2],RaceCheckpoints[progress][0],RaceCheckpoints[progress][1],RaceCheckpoints[progress][2],CHECK_SIZE);
	else SetPlayerRaceCheckpoint(playerid,checktype,RaceCheckpoints[progress][0],RaceCheckpoints[progress][1],RaceCheckpoints[progress][2],RaceCheckpoints[progress+1][0],RaceCheckpoints[progress+1][1],RaceCheckpoints[progress+1][2],CHECK_SIZE);
}


StartRace()
{

	for(new i;i<MAX_PLAYERS;i++)
	{
		//printf("StartRace FULL %d %d", gGrided[gScores2[i][0]],  gScores2[i][0]);
		if (IsPlayerConnected(i) && xRaceBuilding[i] == 0 && spawned[i] == 1 && gPlayerData[i][pIngame] == 1)
		{
			printf("DEBUG START RACE");
			GameTextForPlayer(i,"~W~GO", 2000, 5);
			TogglePlayerControllable(i, 1);
			PlaySoundForPlayer(i, 1057);
		}
	}
	gRaceStart=GetTickCount();
	KillTimer(gCountdowntimer);
	KillTimer(gEndRacetimer);
	gEndRacetimer = SetTimer("nextRaceCountdown",1000,1);
	gRaceStarted = 1;
}

public nextRaceCountdown()
{
	gTrackTime--;
	switch (gTrackTime)
	{
	    case 6:
	    {
			RemovePlayersFromVehicles();
	    }
	    case 1:
	    {
			racecount++;
			if (racecount == RACES_TILL_MODECHANGE)GameModeExit();
			changetrack();
			
	    }
	    case 20,30:
	    {
			new msg[128];
			format(msg, sizeof(msg), "{00DDDD}[ИНФО]{FFFFFF} До старта следующей гонки осталось {FFD700}%d {FFFFFF}секунд.", gTrackTime);
			SendClientMessageToAll(-1, msg);
	    }
	    case 10:
	    {
			countVotes();
	    }
	}
}

public Countdowntimer()
{
	gCountdown--;
	switch (gCountdown)
	{
		case 0:
		{
			StartRace();
		}
		case 2,1:
		{
			new message[256];
			format(message, sizeof(message), "%d", gCountdown);

			for (new i; i < MAX_PLAYERS; i++)
			{
				if (IsPlayerConnected(i) && xRaceBuilding[i] == 0 && spawned[i] == 1 && gPlayerData[i][pReady])
				{
					TogglePlayerControllable(i, false);
					PlaySoundForPlayer(i, 1056);
					GameTextForPlayer(i, message, 750, 5);
				}
			}
		}
		case 4,3:
		{
			new message[256];
			format(message, sizeof(message), "%d", gCountdown);

			for (new i; i < MAX_PLAYERS; i++)
			{
				if (IsPlayerConnected(i) && xRaceBuilding[i] == 0 && spawned[i] == 1 && gPlayerData[i][pReady])
				{
					TogglePlayerControllable(i, false);
					GameTextForPlayer(i, message, 750, 5);
				}
			}
		}
		case 5:
		{
			new message[256];
			format(message, sizeof(message), "%d", gCountdown);

			for (new i = 0; i < MAX_PLAYERS; i++)
			{
				if (IsPlayerConnected(i) && xRaceBuilding[i] == 0 && spawned[i] == 1 && gPlayerData[i][pReady])
				{
					TogglePlayerControllable(i, false);
					SetCameraBehindPlayer(i);
					GameTextForPlayer(i, message, 750, 5);
				}
			}
		}
		case 10,20,30,40,50,60,70,80,90:
		{
			new tmpmsg[256];
			format(tmpmsg, sizeof(tmpmsg), "~w~RACE STARTING IN ~y~%d ~w~SECONDS", gCountdown);
			for (new i = 0; i < MAX_PLAYERS; i++)
			{
				if (IsPlayerConnected(i) && gPlayerData[i][pReady])
				{
					GameTextForPlayer(i, tmpmsg, 4000, 4);
				}
			}
		}
	}

	return 1;
}




strtok(const string[], &index)
{
	new length = strlen(string);
	while ((index < length) && (string[index] <= ' '))
	{
		index++;
	}

	new offset = index;
	new result[20];
	while ((index < length) && (string[index] > ' ') && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string[index];
		index++;
	}
	result[index - offset] = EOS;
	return result;
}


// timeconvert code mainly from Dabombber
timeconvert(Time, &Minutes, &Seconds, &MSeconds)
{
	new Float:fTime = floatdiv(Time, 60000);
    Minutes = floatround(fTime, floatround_tozero);
    Seconds = floatround(floatmul(fTime - Minutes, 60), floatround_tozero);
    MSeconds = floatround(floatmul(floatmul(fTime - Minutes, 60) - Seconds, 1000), floatround_tozero);
}


PlaySoundForPlayer(playerid, soundid)
{
	new Float:pX, Float:pY, Float:pZ;
	GetPlayerPos(playerid, pX, pY, pZ);
	PlayerPlaySound(playerid, soundid,pX, pY, pZ);
}





public PutPlayerInVehicleTimed(playerid, veh, slot)
{
	gPlayerData[playerid][pIngame] = 1;
	PutPlayerInVehicle(playerid,veh,slot);
	SetCameraBehindPlayer(playerid);
	if(gRaceStarted==0)TogglePlayerControllable(playerid,false);
	return 1;
}
public OnPlayerExitedMenu(playerid)
{
	TogglePlayerControllable(playerid,1);
    inCarsMenu[playerid] = 0;
    
	return 1;
}

public OnPlayerConnect(playerid)
{
    printf("[DEBUG] OnPlayerConnect: playerid=%d", playerid);
    TogglePlayerSpectating(playerid, true); // важно
    gPlayerData[playerid][pReady] = false;
	gPlayerData[playerid][pIngame] = false;
    CreateSIObjects(playerid);
    new name[MAX_PLAYER_NAME], path[64];
    GetPlayerName(playerid, name, sizeof(name));
    format(path, sizeof(path), "Users/%s.ini", name);

    if (fexist(path)) {
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Авторизация", "Введите пароль:", "Войти", "Выход");
    } else {
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Регистрация", "Пароль:", "Ок", "Выход");
    }
    
    postLoginInited[playerid] = 0;

    return 1;
}

public RespawnPlayer(playerid)
{
    SetSpawnInfo(playerid, 0, gPlayerData[playerid][pSkin],
                 27.24 + random(2), 3422.45, 6.2, 0.0, 0, 0, 0, 0, 0, 0);
    TogglePlayerSpectating(playerid, false);
    //SpawnPlayer(playerid);
    return 1;
}
public HideXPText(playerid)
{
    if (TXP[playerid]) {
        TextDrawHideForPlayer(playerid, TXP[playerid]);
        TextDrawDestroy(TXP[playerid]);
        TXP[playerid] = Text:INVALID_TEXT_DRAW;
    }
    return 1;
}
public OnPlayerDisconnect(playerid, reason)
{   
    KillTimer(pullMoneyTimer[playerid]);
    spawned[playerid]=0;
#if defined SHOW_JOINS_PARTS
    new pname[MAX_PLAYER_NAME], pmsg[256];
    GetPlayerName(playerid, pname, sizeof(pname));

    new rank = gPlayerData[playerid][pRank];
    new color = RankColors[rank];

    format(pmsg, sizeof(pmsg), "*** {%06x}[%s]{FFFFFF} %s покинул сервер", (color >>> 8), RankNames[rank], pname);
    SendClientMessageToAll(COLOR_TEMP, pmsg);
#endif

	//for(new i;i<MAX_PLAYERS;i++)TextDrawHideForPlayer(i,txtVar3[gTotalRacers]);//total racers  LIMITATION atm will only work with 9 people, if more may crash server
	//gTotalRacers--;
	//new tmp[5];
	//format(tmp,5,"/%d",gTotalRacers);
	//TextDrawSetString(Ttotalracers,tmp);
	//for(new i;i<MAX_PLAYERS;i++)TextDrawShowForPlayer(i,txtVar3[gTotalRacers]);//total racers  LIMITATION atm will only work with 9 people, if more may crash server
    xRaceBuilding[playerid]=0;
	gScores[playerid][1]=0;
	//TextDrawSetString(Tappend[playerid],tmp);
	TextDrawHideForPlayer(playerid, Ttime);
	TextDrawHideForPlayer(playerid, Tappend[playerid]);
	TextDrawHideForPlayer(playerid, Tposition[playerid]);
	TextDrawHideForPlayer(playerid, Ttotalracers);
	TextDrawDestroy(Tappend[playerid]);
	TextDrawDestroy(Tposition[playerid]);
	
	TextDrawHideForPlayer(playerid, TRankHUD[playerid]);
	TextDrawDestroy(TRankHUD[playerid]);
	TRankHUD[playerid] = Text:INVALID_TEXT_DRAW;
	PullMoney(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, WEAPON:reason)
{

	//spawned[playerid]=0;
	TogglePlayerSpectating(playerid, true); // замораживаем экран
    SetTimerEx("RespawnPlayer", 3000, false, "d", playerid); // автоспавн через 2 секунды
/*	while (gPlayerProgress[playerid]>0)
	{
		RaceCheckpoints[gPlayerProgress[playerid]+1][3] = RaceCheckpoints[gPlayerProgress[playerid]+1][3] - 1.0;
		gPlayerProgress[playerid]--;
	}
*/
	return 1;
}


public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}



public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}



public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (!response) return Kick(playerid); // Нажал "Выход"

    new name[MAX_PLAYER_NAME], path[64];
    GetPlayerName(playerid, name, sizeof(name));
    format(path, sizeof(path), "Users/%s.ini", name);

    if (dialogid == DIALOG_LOGIN)
    {
        printf("[DEBUG] DIALOG_LOGIN started for playerid=%d", playerid);

        new File:f = fopen(path, io_read);
        if (!f)
        {
            printf("[DEBUG] fopen FAILED on path: %s", path);
            return 1;
        }

        new line[64];
        if (!fread(f, line))
        {
            printf("[DEBUG] fread FAILED for playerid=%d", playerid);
            fclose(f);
            return 1;
        }
        fclose(f);
        printf("[DEBUG] raw line = %s", line);

		new key[32], val[32], idx = 0;
		strmid(key, strtok(line, idx), 0, sizeof(key));
		strmid(val, strtok(line, idx), 0, sizeof(val));

		if (key[0] == '\0' || val[0] == '\0')
		{
		    printf("[DEBUG] strtok FAILED to parse: %s", line);
		    return 1;
		}
		printf("[DEBUG] parsed: key=%s | val=%s", key, val);


        printf("[DEBUG] inputtext=%s | hash(inputtext)=%d | val=%d",
               inputtext, SimpleHash(inputtext), strval(val));

        new debugResult[16];
        if (SimpleHash(inputtext) == strval(val))
        {
            format(debugResult, sizeof(debugResult), "SUCCESS");
            printf("[DEBUG] Авторизация успешна");
            gPlayerData[playerid][pPassword] = SimpleHash(inputtext);
            gPlayerData[playerid][pLoggedIn] = 1;

            LoadPlayerData(playerid); // включает SetSpawnInfo и SpawnPlayer

            SendClientMessage(playerid, -1, "{00FF00}[УСПЕХ]{FFFFFF} Авторизация успешна!");
        }
        else
        {
            format(debugResult, sizeof(debugResult), "FAIL");
            printf("[DEBUG] Неверный пароль");

            ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT,
                             "Авторизация", "Неверный пароль. Повторите попытку:", "Войти", "Выход");
        }

        printf("[DEBUG] OnDialogResponse: DIALOG_LOGIN | playerid=%d | result=%s", playerid, debugResult);
        return 1;
    }

    if (dialogid == DIALOG_REGISTER)
    {
        new File:f = fopen(path, io_write);
        printf("[DEBUG] OnDialogResponse: DIALOG_REGISTER | playerid=%d", playerid);

        new line[128];
        format(line, sizeof(line), "password %d\n", SimpleHash(inputtext)); fwrite(f, line);
        format(line, sizeof(line), "rank 0\n"); fwrite(f, line);
        format(line, sizeof(line), "wins 0\n"); fwrite(f, line);
        format(line, sizeof(line), "money 1000\n"); fwrite(f, line);
        format(line, sizeof(line), "skin 137\n"); fwrite(f, line);
		format(line, sizeof(line), "xp 0\n"); fwrite(f, line);
        fclose(f);

        gPlayerData[playerid][pLoggedIn] = 1;
        gPlayerData[playerid][pSkin] = 137;
		gPlayerData[playerid][pPassword] = SimpleHash(inputtext);
		gPlayerData[playerid][pMoney] = 1000;
		for (new i = 0; i < CARS_NUMBER; ++i) {
            gPlayerData[playerid][pBoughtCarsHealth][i] = 0;
            gPlayerData[playerid][pRentedCarRaces][i] = 0;
            gPlayerData[playerid][pBoughtCarColor][i] = -1;
            gPlayerData[playerid][pRentedCarColor][i] = -1;
		}
		gPlayerData[playerid][pCurrentCar] = -1;
        SetSpawnInfo(playerid, 0, 137, 27.24 + random(2), 3422.45, 6.2, 0.0,
                     0, 0, 0, 0, 0, 0);
        TogglePlayerSpectating(playerid, false);
        //SpawnPlayer(playerid);
        InitPlayerInterface(playerid);
        return 1;
    }

    return 0;
}

stock LoadPlayerData(playerid)
{
    printf("[DEBUG] LoadPlayerData");

    new name[MAX_PLAYER_NAME], path[64];
    GetPlayerName(playerid, name, sizeof(name));
    format(path, sizeof(path), "Users/%s.ini", name);

    new File:f = fopen(path, io_read);
    if (!f)
    {
        printf("[DEBUG] LoadPlayerData: FAILED to open %s", path);
        return;
    }

    new line[64];
    new key[32], val[32];
    new idx;

    while (fread(f, line))
    {
        idx = 0;
        strmid(key, strtok(line, idx), 0, sizeof(key));
        strmid(val, strtok(line, idx), 0, sizeof(val));

        if (key[0] == '\0' || val[0] == '\0')
        {
            printf("[DEBUG] LoadPlayerData: strtok FAILED on line: %s", line);
            continue;
        }

        printf("[DEBUG] LoadPlayerData: key=%s | val=%s", key, val);

		if (!strcmp(key, "wins", true))     gPlayerData[playerid][pWins]  = strval(val);
        else if (!strcmp(key, "money", true))    gPlayerData[playerid][pMoney] = strval(val);
        else if (!strcmp(key, "skin", true))     gPlayerData[playerid][pSkin]  = strval(val);
        else if (!strcmp(key, "currentCar", true)) gPlayerData[playerid][pCurrentCar] = strval(val);
		else if (!strcmp(key, "xp", true)) {
		    gPlayerData[playerid][pXP] = strval(val);
		    gPlayerData[playerid][pRank] = GetPlayerRankByXP(gPlayerData[playerid][pXP]);
		}
		
		
        for (new i = 0; i < CARS_NUMBER; ++i) {
            new line[128];
            format(line, 128, "boughtCars%d", i);
            if (!strcmp(key, line, true)) gPlayerData[playerid][pBoughtCarsHealth][i] = strval(val);
            format(line, 128, "rentedCars%d", i);
            if (!strcmp(key, line, true)) gPlayerData[playerid][pRentedCarRaces][i] = strval(val);
            format(line, 128, "boughtCarColor%d", i);
            if (!strcmp(key, line, true)) gPlayerData[playerid][pBoughtCarColor][i] = strval(val);
            format(line, 128, "rentedCarColor%d", i);
            if (!strcmp(key, line, true)) gPlayerData[playerid][pRentedCarColor][i] = strval(val);
        }
    }

    fclose(f);
	SetPlayerMoney(playerid,gPlayerData[playerid][pMoney]);
    SetSpawnInfo(playerid, 0, gPlayerData[playerid][pSkin],
                 27.24 + random(2), 3422.45, 6.2, 0.0, 0, 0, 0, 0, 0, 0);
    TogglePlayerSpectating(playerid, false);
    
    //SpawnPlayer(playerid);

	InitPlayerInterface(playerid);


    printf("[DEBUG] LoadPlayerData: playerid=%d | skin=%d", playerid, gPlayerData[playerid][pSkin]);
}

SetPlayerMoney(playerid, cash)
{
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, cash);
    return 1;
}

stock InitPlayerInterface(playerid)
{
    //if (gTotalRacers == 0)
    //    LoadRace(gTrackName);

    //SendClientMessage(playerid, COLOR_TEMP, "Welcome to Adrenaline 2.0 by Paige. The #1 SA-MP Racing mode! NEW: Can now make and save races in-game!");
    //SendClientMessage(playerid, COLOR_TEMP, "Команды: '/newcar' '/rescueme' '/ready'");
	new msg1[144], msg2[144], msg3[144];
	
	format(msg1, sizeof(msg1), "{FFD700}Welcome to {FF5500}Adrenaline 2.0{FFD700} by {00DDDD}Paige{FFFFFF}.");
	format(msg2, sizeof(msg2), "The {FF5500}#1 SA-MP Racing{FFFFFF} mode! {00FF00}NEW{FFFFFF}: in-game race creation and saving.");
	format(msg3, sizeof(msg3), "{00DDDD}Команды:{FFFFFF} {00FF00}/newcar{FFFFFF}, {00FF00}/rescueme{FFFFFF}, {00FF00}/ready");
	
	SendClientMessage(playerid, -1, msg1);
	SendClientMessage(playerid, -1, msg2);
	SendClientMessage(playerid, -1, msg3);

    // Цвет ранга
    new rank = gPlayerData[playerid][pRank];
    new color = RankColors[rank];

    // Пониженное положение (Y = 120.0 вместо 80.0)
    TRankHUD[playerid] = TextDrawCreate(500.0, 120.0, "_");
    TextDrawFont(TRankHUD[playerid], 1);
    TextDrawLetterSize(TRankHUD[playerid], 0.25, 1.0);
    TextDrawColor(TRankHUD[playerid], color); // цвет по рангу
    TextDrawSetOutline(TRankHUD[playerid], 1);
    TextDrawSetShadow(TRankHUD[playerid], 0);
    TextDrawAlignment(TRankHUD[playerid], 1);

    UpdatePlayerRankHUD(playerid);
    TextDrawShowForPlayer(playerid, TRankHUD[playerid]);
}







	//redesigned high score handling code done by kynen
ReadHighScoreList(track[256], display, playerid, all)
{       //READ and DISPLAY Highscorelist
	new HSList[HIGH_SCORE_SIZE][rStats];                                //Takes params trackname, if it is to be displayed on screen
	new FiPo[255];                                                      //the player requesting the displaying and if it is to be
	new himsg[255];                                                     //displayed to all clients

	if(strcmp(track, "", true ) )
	{                                     //if a parameter isn't passed
		track = gTrackName;                                               //use current track
	}

	format(FiPo, sizeof(FiPo), "%s.txt", track);
	if(fexist(FiPo))
	{
		new File: hsfile = fopen(FiPo, io_read);
		new line[256];
		new temp[256];
		new idx;
		if (display)
		{
			format(himsg, sizeof(himsg),"Список лидеров для %s\n", track);
			if(playerid==-1 || IsPlayerAdmin(playerid) && all)
			{
				SendClientMessageToAll(COLOR_TEMP, himsg);             //Sweet khaki color... :D
			} else {
				SendClientMessage(playerid, COLOR_TEMP, himsg);
			}
		}
		for(new i = 0; i <= sizeof(HSList)-1; i++)
		{
			fread(hsfile, line, sizeof(line));
			temp = strtok(line, idx);
			strmid(HSList[i][rName], temp, 0, strlen(temp), 255);     //read racename (to be compatible
			temp = strtok(line, idx);                                 //
			HSList[i][rTime] = strval(temp);                          //convert record to int
			temp = strtok(line, idx);
			strmid(HSList[i][rRacer], temp, 0, strlen(temp), 255);
			idx = 0;                                                  //reset idx to read more highscores
			if (HSList[i][rTime] == 0)
			{                              //check if record is not set (0) previously
				if(!display)
				{                                         //No need to return if it is being displayed
					fclose(hsfile);
					return (HSList);                                  //if list ends, return what there was
				}
			}
			if (display)
			{
				new Minutes, Seconds, MSeconds, sSeconds[5], sMSeconds[5];
				timeconvert(HSList[i][rTime], Minutes, Seconds, MSeconds);
				if (Seconds < 10)format(sSeconds, sizeof(sSeconds), "0%d", Seconds);
				else format(sSeconds, sizeof(sSeconds), "%d", Seconds);
				if (MSeconds < 100)format(sMSeconds, sizeof(sMSeconds), "0%d", MSeconds);
				else format(sMSeconds, sizeof(sMSeconds), "%d", MSeconds);
				if (Minutes != 50)	format(himsg, sizeof(himsg), "{00DDDD}[РЕКОРД]{FFFFFF} #%d — {FFD700}%d:%s.%s{FFFFFF}, установлен {00FF00}%s{FFFFFF}\n", i+1, Minutes, sSeconds, sMSeconds, HSList[i][rRacer]);
				else format(himsg, sizeof(himsg),"\n");
				if(playerid==-1 || IsPlayerAdmin(playerid) && all)
				{
					SendClientMessageToAll(COLOR_TEMP, himsg);        //Sweet khaki color... :D
				} else {
					SendClientMessage(playerid, COLOR_TEMP, himsg);
				}
			}
		}
		fclose(hsfile);
	} else {                                                            //if client passed as param a race that doesn't exist
	format(himsg, sizeof(himsg),"Трек '%s' не существует.\n", track);
	SendClientMessage(playerid, COLOR_TEMP, himsg);                 //Send errormsg privately even if admin

	}
	if(!display)
	{                                                      //No need to return if it is being displayed
		return (HSList);                                                  //so warning 209 can be ignored.
	}
	return (HSList);
}

	//redesigned high score handling code done by kynen
CheckAgainstHighScore(playerid, time)
{
	new RaceInfo[HIGH_SCORE_SIZE][rStats];
	RaceInfo = ReadHighScoreList(gTrackName, 0, 0, 0);
	//Get current track highscorelist
	new playername2[MAX_PLAYER_NAME];
	GetPlayerName(playerid, playername2, MAX_PLAYER_NAME);
	new recordflag=-1;
	//Init to -1 or it will be 0 and fail to work
	new pflag=-1;
	for(new i = 0; i < sizeof(RaceInfo); i++)
	{
	//run through highscorelist to see if new highscore
		if (RaceInfo[i][rTime] == 0)
		{
	//check if record is not set (0) previously
			RaceInfo[i][rTime] = 3000000;
	//if no previous record, set dummy record
		}
		if (strcmp(RaceInfo[i][rRacer], playername2) == 0 && pflag ==-1)
		{ //check for personal best score
			pflag = i;
	      //mark where best personal record is
		}
		if (time < RaceInfo[i][rTime] && recordflag ==-1 && (pflag == -1 || pflag == i) )
		{               //new record
	           //personal flag must always be equal or nonexistant (-1) for a valid (personal) record
			new newrecordmessage[256];
			if (i+1 == 1) printf("НОВЫЙ РЕКОРД - %s", playername2);
			format(newrecordmessage, sizeof(newrecordmessage), "{00DDDD}[РЕКОРД]{FFFFFF} Новый рекорд #{FFD700}%d{FFFFFF} на трассе {FFD700}%s{FFFFFF} установлен {00FF00}%s{FFFFFF}\n", i+1, gTrackName, playername2);
			SendClientMessageToAll(COLOR_TEMP, newrecordmessage);
			recordflag = i;
			//Record number
		}
	}
	if (recordflag>-1)
	{
	//new highscore
		new tmp1[255];
		format(tmp1,sizeof(tmp1),"%s.txt", gTrackName);     //time to update list (file)
		if(fexist(tmp1))
		{
			new File: file2 = fopen(tmp1, io_write);
			new recordmessage[256];
			new recmsg2[256];
			format(recordmessage, sizeof(recordmessage),"%s %d %s\n" , gTrackName, time, playername2);
			for(new i = 0; i < sizeof(RaceInfo); i++)
			{
				if(i == recordflag)
				{
				//record goes to correct place in list
					fwrite(file2,recordmessage);
				}
				if(strcmp(RaceInfo[i][rRacer], playername2)==0)
				{
		//skip all records that matches racername
					continue;
				}
				if(RaceInfo[i][rTime] == 3000000)
				{
		//ignore dummy records
					break;
				}
				format(recmsg2, sizeof(recmsg2), "%s %d %s\n", gTrackName, RaceInfo[i][rTime], RaceInfo[i][rRacer]);
				fwrite(file2,recmsg2);
		//write from old record list
			}
			fclose(file2);
		} else {
			SendClientMessageToAll(COLOR_TEMP, "Ошибка: Файла трека не существует");
		}
	}
}

stock GetPlayerRankByXP(xp)
{
    for (new i = MAX_RANKS - 1; i >= 0; i--)
    {
        if (xp >= RankXP[i])
            return i;
    }
    return 0;
}

stock CalculateXPReward(totalPlayers, position)
{
    if (invalidateResult == 1) {
        return 0;
    }
    if (totalPlayers <= 1) return 0;

    new xpBase = 10;
    new placePoints = totalPlayers - position + 1;

    return placePoints * xpBase;
}

stock CalculateMoneyReward(totalPlayers, position)
{
    if (invalidateResult == 1) {
        return 0;
    }
    if (totalPlayers <= 1) return 0;

    new xpBase = 10;
    new placePoints = totalPlayers - position + 1;

    return placePoints * xpBase;
}

stock SavePlayerData(playerid)
{
    new name[MAX_PLAYER_NAME], path[64];
    GetPlayerName(playerid, name, sizeof(name));
    format(path, sizeof(path), "Users/%s.ini", name);

    new File:f = fopen(path, io_write);
    if (!f) return;

    new line[128];
    format(line, sizeof(line), "password %d\n", gPlayerData[playerid][pPassword]); fwrite(f, line);
    format(line, sizeof(line), "xp %d\n", gPlayerData[playerid][pXP]); fwrite(f, line);
    format(line, sizeof(line), "rank %d\n", gPlayerData[playerid][pRank]); fwrite(f, line);
    format(line, sizeof(line), "wins %d\n", gPlayerData[playerid][pWins]); fwrite(f, line);
    format(line, sizeof(line), "money %d\n", gPlayerData[playerid][pMoney]); fwrite(f, line);
    format(line, sizeof(line), "skin %d\n", gPlayerData[playerid][pSkin]); fwrite(f, line);
    for (new i = 0; i < CARS_NUMBER; ++i) {
        format(line, sizeof(line), "boughtCars%d %d\n", i, gPlayerData[playerid][pBoughtCarsHealth][i]); fwrite(f, line);
        format(line, sizeof(line), "rentedCars%d %d\n", i, gPlayerData[playerid][pRentedCarRaces][i]); fwrite(f, line);
        format(line, sizeof(line), "boughtCarColor%d %d\n", i, gPlayerData[playerid][pBoughtCarColor][i]); fwrite(f, line);
        format(line, sizeof(line), "rentedCarColor%d %d\n", i, gPlayerData[playerid][pRentedCarColor][i]); fwrite(f, line);
    }
    format(line, sizeof(line), "currentCar %d\n", gPlayerData[playerid][pCurrentCar]); fwrite(f, line);

    fclose(f);
}

stock UpdatePlayerRankHUD(playerid)
{
    new xp = gPlayerData[playerid][pXP];
    new rank = gPlayerData[playerid][pRank];
    //printf("%d:rank", rank);
    new maxXP = (rank + 1 < MAX_RANKS) ? RankXP[rank + 1] : RankXP[rank];
    new readyText[128];

    if (gPlayerData[playerid][pReady])
        format(readyText, sizeof(readyText), "~n~~g~[READY]");
    else
        format(readyText, sizeof(readyText), "~n~~r~[NOT READY]");

    new line[128];
    format(line, sizeof(line), "RANK: %s~n~XP: %d / %d%s", RankNames[rank], xp, maxXP, readyText);

    TextDrawSetString(TRankHUD[playerid], line);
 // rintf("%d:id %d:xpp%d:maxp", playerid, xp, maxXP);
}


HighScore(Track)
{
	#pragma unused Track
	new recordtimestr[20], recordtime;
	new racer[64]; // не нужен такой большой буфер
	new HighScoreString[144]; // строго по лимиту

	new tmp1[128];
	format(tmp1, sizeof(tmp1), "%s.txt", gTrackName);

	if (!fexist(tmp1))
	{
	    new File: file1 = fopen(tmp1, io_write);
	    fclose(file1);
	}

	new File: file = fopen(tmp1, io_read);
	new line[256], track[64];
	new idx;

	fread(file, line, sizeof(line));
	track = strtok(line, idx);
	recordtimestr = strtok(line, idx);
	racer = strtok(line, idx);
	fclose(file);

	recordtime = strval(recordtimestr);

	new Minutes, Seconds, MSeconds, sSeconds[5], sMSeconds[5];
	if (recordtime > 0)
	{
		timeconvert(recordtime, Minutes, Seconds, MSeconds);

		format(sSeconds, sizeof(sSeconds), Seconds < 10 ? "0%d" : "%d", Seconds);
		format(sMSeconds, sizeof(sMSeconds), MSeconds < 100 ? "0%d" : "%d", MSeconds);

		// Цветной формат с меткой [РЕКОРД]
		format(HighScoreString, sizeof(HighScoreString),
			"{00DDDD}[РЕКОРД]{FFFFFF} %d:%s.%s — {00FF00}%s{FFFFFF}",
			Minutes, sSeconds, sMSeconds, racer);
	}
	else
	{
		format(HighScoreString, sizeof(HighScoreString),
			"{00DDDD}[РЕКОРД]{FFFFFF} Нет текущего рекорда.");
	}

	return HighScoreString;
}


/*
findHighest()
{
	new t = gScores2[0][1];
	new index;
	for(new i = 0; i < 13;i++)
	{

	    if (gScores2[i][1]>t)
	    {
			index=i;
			t = gScores2[i][1];
	    }
	}
	gScores2[index][1]=0;
	return index;
}
*/
sscanf(string[], format[], {Float,_}:...)//sscanf by Y_Less
{
	new
		formatPos,
		stringPos,
		paramPos = 2,
		paramCount = numargs();
	while (paramPos < paramCount && string[stringPos])
	{
		switch (format[formatPos])
		{
			case '\0': break;
			case 'i', 'd': setarg(paramPos, 0, strval(string[stringPos]));
			case 'c': setarg(paramPos, 0, string[stringPos]);
			case 'f': setarg(paramPos, 0, _:floatstr(string[stringPos]));
			case 's':
			{
				new
					end = format[formatPos + 1] == '\0' ? '\0' : ' ',
					i;
				while (string[stringPos] != end) setarg(paramPos, i++, string[stringPos++]);
				setarg(paramPos, i, '\0');
			}
			default: goto skip;
		}
		while (string[stringPos] && string[stringPos] != ' ') stringPos++;
		while (string[stringPos] == ' ') stringPos++;
		paramPos++;
		skip:
		formatPos++;
	}
	return format[formatPos] ? 0 : 1;
}

stock strreplace(string[], search, replace)
{
    for (new i = 0; i < strlen(string); i++)
    {
        if (string[i] == search) string[i] = replace;
    }
}

stock SimpleHash(const str[])
{
	new hash = 0;
	for (new i = 0; str[i] != '\0'; i++)
	{
		hash = (hash * 31 + str[i]) % 100000; // простая комбинация, чтобы были разные значения
	}
	return hash;
}

quickSort(array_size)
{
  print("quickSort()");
  q_sort(0, array_size - 1);
}

q_sort(left, right)
{
  new pivot, l_hold, r_hold;

  l_hold = left;
  r_hold = right;
  pivot = gScores2[left][1];
  new what = gScores2[left][0];
  while (left < right)
  {
    while ((gScores2[right][1] >= pivot) && (left < right))
      right--;
    if (left != right)
    {
      gScores2[left][1] = gScores2[right][1];
      gScores2[left][0] = gScores2[right][0];
      left++;
    }
    while ((gScores2[left][1] <= pivot) && (left < right))
      left++;
    if (left != right)
    {
      gScores2[right][1] = gScores2[left][1];
      gScores2[right][0] = gScores2[left][0];
      right--;
    }
  }
  gScores2[left][1] = pivot;
  gScores2[left][0] = what;
  pivot = left;
  left = l_hold;
  right = r_hold;
  if (left < pivot) q_sort(left, pivot-1);
  if (right > pivot) q_sort(pivot+1, right);
}



//////////////////////////////////////////////////
//// x.x CUSTOM FUNCTIONS (END) ////////////////
//////////////////////////////////////////////////
