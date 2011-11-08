/* Twitter4j Java Library */

// twitter4j import and twitter connection -
import twitter4j.conf.*;
import twitter4j.internal.async.*;
import twitter4j.internal.org.json.*;
import twitter4j.internal.logging.*;
import twitter4j.json.*;
import twitter4j.internal.util.*;
import twitter4j.management.*;
import twitter4j.auth.*;
import twitter4j.api.*;
import twitter4j.util.*;
import twitter4j.internal.http.*;
import twitter4j.*;
import twitter4j.internal.json.*;
String shown_message ="";
String consumer_key = "niYXDjx5pyzp8qlZXqaAw";
String consumer_secret = "mNfQyu7tQ2CceuQUrfCOInxSn447hF7wcT5IisjM8";
String oauth_token = "405995845-vg1cdDNo6nZogpFyR6muBIL3UJCvdStb7owAKcQU";
String oauth_token_secret = "r1bgGOScvcwzWUTq7tDQtV8cfOyL05iSJrcw";
AccessToken token;

void queryTwitter(String searchQuery){
  Twitter twitter = new TwitterFactory().getInstance();
  twitter.setOAuthConsumer(consumer_key, consumer_secret);
  token = new AccessToken(oauth_token, oauth_token_secret);
  twitter.setOAuthAccessToken(token);
 // twitter.setOAuthAccessToken(new AccessToken( oauth_token, oauth_token_secret) );
  try {
    
     Query query = new Query(searchQuery);
     query.setRpp(100);
     QueryResult result = twitter.search(query);
 
     ArrayList tweets = (ArrayList) result.getTweets();
     twitterResponse = "";
     for (int i = 0; i < tweets.size(); i++) {
       Tweet t = (Tweet) tweets.get(i);
       String msg = t.getText();
       twitterResponse += msg+" ";

     }  
  }
  catch (TwitterException te) {
    println("Couldn't connect: " + te);
  }
}

void newTopic(){
  nextSwitchLetter = 0;
  currTopic = int(random(keywords.length));
  queryTwitter(keywords[currTopic]);
}
