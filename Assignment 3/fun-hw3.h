#ifndef __FUN_HW3_H
#define __FUN_HW3_H

#include <stdbool.h>

typedef enum { ItemType_Set, ItemType_Send, ItemType_Schedule, ItemType_Recipient, ItemType_Mail } ItemType;
typedef enum { NodeType_LIST, NodeType_SET, NodeType_SEND, NodeType_SCHEDULE, NodeType_RECIPIENT, NodeType_MAIL } NodeType;

typedef struct Identifier {
        char* name;
        int line;
} Identifier;

struct NodeDateTime {
    char *date;
    char *time;
    char *console;
    bool isPrinted;
    struct NodeDateTime *next;
};

typedef struct NodeSet {
        char * identifier;
        char * value;
        int line;
} NodeSet;

typedef struct NodeSend {
        char * message;
        int line;
        struct TreeNode * head;
        bool isHandled;
        int scope;
} NodeSend;

typedef struct NodeSchedule {
        char * date;
        int line_date;
        char * time;
        int line_time;
        struct TreeNode * head;
        bool isValidDate;
        bool isValidTime;
        bool isPrinted;
} NodeSchedule;

typedef struct NodeRecipient {
        char * recipientName;
        int line;
        bool isHandled;
        char * address;
        int scope;
} NodeRecipient;

typedef struct NodeMail {
        char * mailFrom;
        struct TreeNode * head;
        int scope;
} NodeMail;

typedef struct ListNode {
        ItemType itemType;
        struct TreeNode * next;
        struct TreeNode * item;
} ListNode;

typedef union {
        NodeSet set;
        NodeSend send;
        NodeSchedule sch;
        NodeRecipient rcp;
        NodeMail mail;
        ListNode list;
} Node;


typedef struct TreeNode{
	NodeType nodeType;
  Node * nodePtr;
} TreeNode;

TreeNode * mkLIST ( TreeNode *next, TreeNode *item, ItemType type);
TreeNode * mkSET (const char* name, const char* value, int line);
TreeNode * mkMAIL (TreeNode *head, const char * address);
TreeNode * mkSCHEDULE (const char * date, const char *time, TreeNode *head, int line_date, int line_time);
TreeNode * mkSEND (const char * value, TreeNode *head, bool isHandled, int line);
TreeNode * mkRECIPIENT (const char *value, const char *address, bool isHandled, int line);
struct NodeDateTime* mkDateTime(char *date, char *time, char *consoleValues, int isPrinted);

void handleSendNode(TreeNode* node);
void handleRecipientNode(TreeNode* node);
void handleScheduleNode(TreeNode* node);
void handleIdents(TreeNode* node);

char *getIdent(char *name, int scope, int maxLine);
void getIdentRecursive(TreeNode *node, char *name, char **latest, int scope, int maxLine);

void printNotifications(TreeNode *node);
void printMailBlockNotifications(TreeNode *node, char * mailFrom);
void printScheduleNotifications(TreeNode *node, char *mailFrom, int index, TreeNode *head, char *date, char *time);
void printSendNotifications(TreeNode *node, char * mailFrom, char * message, int index, TreeNode *head);
void printScheduleNotificationsSend(TreeNode *node, char * mailFrom, char * message, int index, TreeNode *head, char * date, char * time, char **console);
void print(struct NodeDateTime* head);

char* scheduleString(char* mailFrom, char* date, char* time, char* to, char* message);
void swap(struct NodeDateTime* node1, struct NodeDateTime* node2);
void sortDateTime(struct NodeDateTime* head);
bool isFirst(TreeNode *head, char* address, int seenIndex);
bool isValidDate(const char* date);
bool compareDate(char* date1, char* time1, char* date2, char* time2);

#endif