%{
#ifdef YYDEBUG
  yydebug = 1;
#endif
#include "fun-hw3.h"
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
void yyerror (const char *msg) /* Called by yyparse on error */ {return; }

TreeNode * root = NULL;
int currentScope = 0;
struct NodeDateTime* dateTimeHead = NULL;
bool isNoError = true;
%}

%union {
  char *value;
  TreeNode *treePtr;
  Identifier identifier;
}

%token <identifier> tIDENT
%token <value> tSTRING
%token <value> tADDRESS
%token <identifier> tDATE
%token <identifier> tTIME


%token tMAIL tENDMAIL tSCHEDULE tENDSCHEDULE tSEND tTO tFROM tSET tCOMMA tCOLON tLPR tRPR tLBR tRBR tAT
%type <treePtr> statements
%type <treePtr> mailBlock
%type <treePtr> setStatement
%type <treePtr> statementList
%type <treePtr> sendStatements
%type <treePtr> sendStatement
%type <treePtr> scheduleStatement
%type <treePtr> recipientList
%type <treePtr> recipient

%start program
%%

program : statements {root = $1; }
;

statements :                                      {$$ = NULL;  }
            | setStatement statements             {$$ = mkLIST ( $2, $1, ItemType_Set);   }
            | mailBlock statements                {$$ = mkLIST ( $2, $1, ItemType_Mail);  }
;

mailBlock : tMAIL tFROM tADDRESS tCOLON statementList tENDMAIL  {$$ = mkMAIL ($5, $3);  currentScope += 1;}
;

statementList :                                         {$$ = NULL;  }
                | setStatement statementList            {$$ = mkLIST ( $2, $1, ItemType_Set);   }     
                | sendStatement statementList           {$$ = mkLIST ( $2, $1, ItemType_Send);  }  
                | scheduleStatement statementList       {$$ = mkLIST ( $2, $1, ItemType_Schedule);   }       
;

sendStatements : sendStatement                          {$$ = mkLIST ( NULL, $1, ItemType_Send);   }
                | sendStatement sendStatements          {$$ = mkLIST ( $2, $1, ItemType_Send);   }
;

sendStatement : tSEND tLBR tIDENT tRBR tTO tLBR recipientList tRBR     {$$ = mkSEND ( $3.name, $7, 0, $3.line);   }
              | tSEND tLBR tSTRING tRBR tTO tLBR recipientList tRBR    {$$ = mkSEND ( $3, $7, 1, -1);   }
;


recipientList : recipient                               {$$ = mkLIST ( NULL, $1, ItemType_Recipient);   }
            | recipient tCOMMA recipientList            {$$ = mkLIST ( $3, $1, ItemType_Recipient);   }
;

recipient : tLPR tADDRESS tRPR                          {$$ = mkRECIPIENT ( $2, $2, 1, -1);   }
            | tLPR tSTRING tCOMMA tADDRESS tRPR         {$$ = mkRECIPIENT ( $2, $4, 1, -1);   }
            | tLPR tIDENT tCOMMA tADDRESS tRPR          {$$ = mkRECIPIENT ( $2.name, $4, 0, $2.line);   }
;

scheduleStatement : tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON sendStatements tENDSCHEDULE {$$ = mkSCHEDULE ( $4.name, $6.name, $9, $4.line, $6.line); }
;

setStatement : tSET tIDENT tLPR tSTRING tRPR    {$$ = mkSET($2.name, $4, $2.line ); }
;


%%
int main () 
{
   if (yyparse())
   {
      printf("ERROR\n");
      return 1;
    } 
    else 
    {
      if (root == NULL){
        return 0;
      }
        handleIdents(root);
        if(isNoError){
          printNotifications(root);
          sortDateTime(dateTimeHead);
          print(dateTimeHead);
        }
        return 0;
    } 
}

TreeNode * mkLIST ( TreeNode *next, TreeNode *item, ItemType type) {
  TreeNode* newNode = (TreeNode*)malloc(sizeof(TreeNode));
  newNode->nodePtr = (Node*)malloc(sizeof(Node));
  
  newNode->nodeType = NodeType_LIST;
  newNode->nodePtr->list.itemType = type;
  newNode->nodePtr->list.next = next;
  newNode->nodePtr->list.item = item;
  
  return newNode;
}


TreeNode * mkSET (const char* name, const char* value, int line) {
  TreeNode* newNode = (TreeNode*)malloc(sizeof(TreeNode));
  newNode->nodeType = NodeType_SET;
  newNode->nodePtr = (Node*)malloc(sizeof(Node));

  newNode->nodePtr->set.identifier = strdup(name);
  newNode->nodePtr->set.value = strdup(value);
  newNode->nodePtr->set.line = line;

  return newNode;
}

TreeNode * mkMAIL (TreeNode *head, const char * address) {
  TreeNode* newNode = (TreeNode*)malloc(sizeof(TreeNode));
  newNode->nodeType = NodeType_MAIL;
  newNode->nodePtr = (Node*)malloc(sizeof(Node));

  newNode->nodePtr->mail.head = head;
  newNode->nodePtr->mail.mailFrom = strdup(address);
  newNode->nodePtr->mail.scope = currentScope;

  return newNode;
}

TreeNode * mkSCHEDULE (const char * date, const char *time, TreeNode *head, int line_date, int line_time) {
  TreeNode* newNode = (TreeNode*)malloc(sizeof(TreeNode));
  newNode->nodeType = NodeType_SCHEDULE;
  newNode->nodePtr = (Node*)malloc(sizeof(Node));

  newNode->nodePtr->sch.head = head;
  newNode->nodePtr->sch.date = strdup(date);
  newNode->nodePtr->sch.line_date = line_date;
  newNode->nodePtr->sch.time = strdup(time);
  newNode->nodePtr->sch.line_time = line_time;
  newNode->nodePtr->sch.isValidDate = false;
  newNode->nodePtr->sch.isValidTime = false;
  newNode->nodePtr->sch.isPrinted = false;

  return newNode;
}

TreeNode * mkSEND (const char * value, TreeNode *head, bool isHandled, int line) {
  TreeNode* newNode = (TreeNode*)malloc(sizeof(TreeNode));
  newNode->nodeType = NodeType_SEND;
  newNode->nodePtr = (Node*)malloc(sizeof(Node));

  newNode->nodePtr->send.message = strdup(value);
  newNode->nodePtr->send.line = line;
  newNode->nodePtr->send.head = head;
  newNode->nodePtr->send.isHandled = isHandled;
  newNode->nodePtr->send.scope = currentScope;

  return newNode;
}

TreeNode * mkRECIPIENT (const char *value, const char *address, bool isHandled, int line) {
  TreeNode* newNode = (TreeNode*)malloc(sizeof(TreeNode));
  newNode->nodeType = NodeType_RECIPIENT;
  newNode->nodePtr = (Node*)malloc(sizeof(Node));

  newNode->nodePtr->rcp.recipientName = strdup(value);
  newNode->nodePtr->rcp.line = line;
  newNode->nodePtr->rcp.isHandled = isHandled;
  newNode->nodePtr->rcp.address = strdup(address);
  newNode->nodePtr->rcp.scope = currentScope;

  return newNode;
}

struct NodeDateTime* mkDateTime(char *date, char *time, char *consoleValues, int isPrinted) {
    struct NodeDateTime* newNodeDateTime = (struct NodeDateTime*)malloc(sizeof(struct NodeDateTime));
    newNodeDateTime->date = strdup(date);
    newNodeDateTime->time = strdup(time);
    newNodeDateTime->console = strdup(consoleValues);
    newNodeDateTime->isPrinted = isPrinted;
    newNodeDateTime->next = NULL;
    return newNodeDateTime;
}

void handleSendNode(TreeNode* node) {
    if (!node->nodePtr->send.isHandled) {
        char* value = getIdent(node->nodePtr->send.message, node->nodePtr->send.scope, node->nodePtr->send.line);
        if (value == NULL) {
            isNoError = false;
            printf("ERROR at line %d: %s is undefined\n", node->nodePtr->send.line, node->nodePtr->send.message);
        } else {
            node->nodePtr->send.message = strdup(value);
            node->nodePtr->send.isHandled = true;
        }
    }

    if (node->nodePtr->send.head != NULL) {
        handleIdents(node->nodePtr->send.head);
    }
}

void handleRecipientNode(TreeNode* node) {
    if (!node->nodePtr->rcp.isHandled) {
        char* value = getIdent(node->nodePtr->rcp.recipientName, node->nodePtr->rcp.scope, node->nodePtr->rcp.line);
        if (value == NULL) {
            isNoError = false;
            printf("ERROR at line %d: %s is undefined\n", node->nodePtr->rcp.line, node->nodePtr->rcp.recipientName);
        } else {
            node->nodePtr->rcp.recipientName = strdup(value);
            node->nodePtr->rcp.isHandled = true;
        }
    }
}

void handleScheduleNode(TreeNode* node) {
  if(isValidDate(node->nodePtr->sch.date)){
    node->nodePtr->sch.isValidDate = true;
  }
  else{
    isNoError = false;
    printf("ERROR at line %d: date object is not correct (%s)\n", node->nodePtr->sch.line_date, node->nodePtr->sch.date);
  }
  int hour, minute;
  sscanf(node->nodePtr->sch.time, "%d:%d", &hour, &minute);
  if((hour >= 0 && hour <= 23) && (minute >= 0 && minute <= 59)){
    node->nodePtr->sch.isValidTime = true;
  }
  else{
    isNoError = false;
    printf("ERROR at line %d: time object is not correct (%s)\n", node->nodePtr->sch.line_time, node->nodePtr->sch.time);
  }
  if(node->nodePtr->sch.head != NULL){
    handleIdents(node->nodePtr->sch.head);
  }
}

void handleIdents(TreeNode* node){
  if(node->nodeType == NodeType_LIST){
    if(node->nodePtr->list.itemType == ItemType_Send){
      handleSendNode(node->nodePtr->list.item);
    }
    if(node->nodePtr->list.itemType == ItemType_Recipient){
      handleRecipientNode(node->nodePtr->list.item);
    }
    if(node->nodePtr->list.itemType == ItemType_Mail){
      if(node->nodePtr->list.item->nodePtr->mail.head != NULL){
        handleIdents(node->nodePtr->list.item->nodePtr->mail.head);
      }
    }
    if(node->nodePtr->list.itemType == ItemType_Schedule){
      handleScheduleNode(node->nodePtr->list.item);
    }
    if(node->nodePtr->list.next != NULL){
      handleIdents(node->nodePtr->list.next);
    }
  }
}

char *getIdent(char *name, int scope, int maxLine){
  char *latest = NULL;
  getIdentRecursive(root, name, &latest, scope, maxLine); 
  return latest;
}

void getIdentRecursive(TreeNode *node, char *name, char **latest, int scope, int maxLine){
  if(node->nodeType == NodeType_LIST){
    if(node->nodePtr->list.itemType == ItemType_Set && node->nodePtr->list.item->nodePtr->set.line <= maxLine){
      if(strcmp(name, node->nodePtr->list.item->nodePtr->set.identifier) == 0){
        *latest = strdup(node->nodePtr->list.item->nodePtr->set.value); 
      }
    }
    if(node->nodePtr->list.next != NULL){
      getIdentRecursive(node->nodePtr->list.next, name, latest, scope, maxLine);
    }
    if(node->nodePtr->list.itemType == ItemType_Mail){
      if(node->nodePtr->list.item->nodePtr->mail.head != NULL && node->nodePtr->list.item->nodePtr->mail.scope == scope){
        getIdentRecursive(node->nodePtr->list.item->nodePtr->mail.head, name, latest, scope, maxLine);
      }
    }
  }
}

void printNotifications(TreeNode *node){
  if(node->nodeType == NodeType_LIST){
    if(node->nodePtr->list.itemType == ItemType_Mail){
      printMailBlockNotifications(node->nodePtr->list.item->nodePtr->mail.head, node->nodePtr->list.item->nodePtr->mail.mailFrom);
    }
    if(node->nodePtr->list.next != NULL){
      printNotifications(node->nodePtr->list.next);
    }
  }
}

void printMailBlockNotifications(TreeNode *node, char * mailFrom){
  if(node->nodeType == NodeType_LIST){
    if(node->nodePtr->list.itemType == ItemType_Send){
      printSendNotifications(node->nodePtr->list.item->nodePtr->send.head, mailFrom, node->nodePtr->list.item->nodePtr->send.message, 0, node->nodePtr->list.item->nodePtr->send.head);
    }
    if(node->nodePtr->list.itemType == ItemType_Schedule){
      printScheduleNotifications(node->nodePtr->list.item->nodePtr->sch.head, mailFrom, 0, node->nodePtr->list.item->nodePtr->sch.head, node->nodePtr->list.item->nodePtr->sch.date, node->nodePtr->list.item->nodePtr->sch.time);
    }
    if(node->nodePtr->list.next != NULL){
      printMailBlockNotifications(node->nodePtr->list.next, mailFrom);
    }
  }
}

void printScheduleNotifications(TreeNode *node, char *mailFrom, int index, TreeNode *head, char *date, char *time){
    if(node->nodeType == NodeType_LIST){
      char *console = (char *)malloc(100);
      strcpy(console, "");
        if(node->nodePtr->list.itemType == ItemType_Send){ 
            printScheduleNotificationsSend(node->nodePtr->list.item->nodePtr->send.head, mailFrom, node->nodePtr->list.item->nodePtr->send.message, 0, node->nodePtr->list.item->nodePtr->send.head, date, time, &console);
            struct NodeDateTime *temp = mkDateTime(date, time, console, 0);
            temp->next = dateTimeHead;
            dateTimeHead = temp;
        }
        if(node->nodePtr->list.next != NULL){
            index += 1;
            printScheduleNotifications(node->nodePtr->list.next, mailFrom, index, head, date, time);
        }
    }
}

void printSendNotifications(TreeNode *node, char * mailFrom, char * message, int index, TreeNode *head){
  if(node->nodeType == NodeType_LIST){
    if(node->nodePtr->list.itemType == ItemType_Recipient){
      if(isFirst(head, node->nodePtr->list.item->nodePtr->rcp.address, index)){ 
      printf("E-mail sent from %s to %s: \"%s\"\n", mailFrom, node->nodePtr->list.item->nodePtr->rcp.recipientName ,message);
      }
    }
    if(node->nodePtr->list.next != NULL){
      index += 1;
      printSendNotifications(node->nodePtr->list.next, mailFrom, message, index, head);
    }
  }
}

void printScheduleNotificationsSend(TreeNode *node, char * mailFrom, char * message, int index, TreeNode *head, char * date, char * time, char **console){
  if (node == NULL || head == NULL || console == NULL) {
        return;
  }
  if(node->nodeType == NodeType_LIST){
    if(node->nodePtr->list.itemType == ItemType_Recipient){
      if(isFirst(head, node->nodePtr->list.item->nodePtr->rcp.address, index)) {
        char *consoleNext = scheduleString(mailFrom,date, time, node->nodePtr->list.item->nodePtr->rcp.recipientName, message);
        if (strlen(*console) == 0) {
          strcpy(*console, consoleNext);
        } else {
          strcat(*console, "\n");
          strcat(*console, consoleNext);
        }
      }
    }
    if(node->nodePtr->list.next != NULL){
      index += 1;
      printScheduleNotificationsSend(node->nodePtr->list.next, mailFrom, message, index, head, date, time, console);
    }
  }
}

void print(struct NodeDateTime* head) {
    struct NodeDateTime* current = head;
    while (current != NULL) {
        printf("%s\n", current->console);
        current = current->next;
    }
}

char* scheduleString(char* mailFrom, char* date, char* time, char* to, char* message) {
  const char* monthNames[] = {"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
  char convertedDate[50];
  int day, month, year;

  sscanf(date, "%d/%d/%d", &day, &month, &year);
  
  sprintf(convertedDate, "%s %d, %d", monthNames[month], day, year);
      
  int length = snprintf(NULL, 0, "E-mail scheduled to be sent from %s on %s, %s to %s: \"%s\"", mailFrom, convertedDate, time, to, message);
  char* scheduledEmailString = (char*)malloc(length + 1);
  sprintf(scheduledEmailString, "E-mail scheduled to be sent from %s on %s, %s to %s: \"%s\"", mailFrom, convertedDate, time, to, message);
  return scheduledEmailString;
}

bool isFirst(TreeNode *head, char* address, int seenIndex){
  int index = 0;
  TreeNode* current = head;
  while(current != NULL){
    if(strcmp(current->nodePtr->list.item->nodePtr->rcp.address, address) == 0){
      return (seenIndex == index);
    }
    current = current->nodePtr->list.next;
    index += 1;
  }
  return false;
}

void swap(struct NodeDateTime* node1, struct NodeDateTime* node2) {
    char *tempDate = node1->date;
    node1->date = node2->date;
    node2->date = tempDate;

    char *tempTime = node1->time;
    node1->time = node2->time;
    node2->time = tempTime;

    char *tempConsole = node1->console;
    node1->console = node2->console;
    node2->console = tempConsole;

    int tempIsPrinted = node1->isPrinted;
    node1->isPrinted = node2->isPrinted;
    node2->isPrinted = tempIsPrinted;
}

void sortDateTime(struct NodeDateTime* head) {
    bool swapped = true;
    struct NodeDateTime *ptr1;
    struct NodeDateTime *ptr2 = NULL;

    if (head == NULL) {
        return;
    }
    while (swapped) {
        swapped = false;
        ptr1 = head;

        while (ptr1->next != ptr2) {
            if (compareDate(ptr1->next->date, ptr1->next->time, ptr1->date, ptr1->time)) {
                swap(ptr1, ptr1->next);
                swapped = true;
            }
            ptr1 = ptr1->next;
        }

        ptr2 = ptr1;
    }
}

bool isValidDate(const char* date) {
  int day, month, year;
  if (sscanf(date, "%d/%d/%d", &day, &month, &year) != 3) {
      return false;
  }

  if (year < 0 || month < 1 || month > 12 || day < 1) {
      return false; 
  }

  int daysInMonth[] = {0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
  
  if (month == 2) {
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
          daysInMonth[2] = 29;  // Leap year
      }
  }

  return day <= daysInMonth[month];
}

bool compareDate(char* date1, char* time1, char* date2, char* time2) {
    int day1, month1, year1, hour1, minute1;
    sscanf(date1, "%d/%d/%d", &day1, &month1, &year1);
    sscanf(time1, "%d:%d", &hour1, &minute1);

    int day2, month2, year2, hour2, minute2;
    sscanf(date2, "%d/%d/%d", &day2, &month2, &year2);
    sscanf(time2, "%d:%d", &hour2, &minute2);

    if (year1 < year2) {
        return true;  
    } else if (year1 > year2) {
        return false; 
    } else {
      if (month1 < month2) {
          return true;
      } else if (month1 > month2) {
          return false;
      } else {
        if (day1 < day2) {
            return true;
        } else if (day1 > day2) {
            return false;
        } else {
          if (hour1 < hour2) {
              return true;
          } else if (hour1 > hour2) {
              return false;
          }
          else {
            return (minute1 <= minute2);
          }
        }
      }
    }
}