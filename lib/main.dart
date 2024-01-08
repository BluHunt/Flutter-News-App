import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'News App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: NewsApp(),
    );
  }
}

class NewsApp extends StatefulWidget {
  @override
  _NewsAppState createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  bool isDarkMode = false;
  String selectedCountry = "us"; // Default country is India
  String selectedCategory = "everything"; // Default category is General
  String apiKey = "3a935e2bb64346f592de9a16ab9a0525";
  String searchText = '';
  bool isSearching = false;

  Future<List<dynamic>>? _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = refreshNews();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: isSearching
              ? TextField(
            onSubmitted: (value) {
              // Trigger search when "Done" or "Enter" is pressed
              setState(() {
                searchText = value;
                _newsFuture = searchNews();
              });
            },
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search News...',
              border: InputBorder.none,
            ),
          )
              : Text('News App'),
          actions: [
            if (isSearching)
              IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () {
                  setState(() {
                    isSearching = false;
                    searchText = '';
                    _newsFuture = refreshNews();
                  });
                },
              )
            else
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    isSearching = true;
                  });
                },
              ),
            IconButton(
              icon: Icon(Icons.brightness_6),
              onPressed: () {
                toggleDarkMode();
              },
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _newsFuture = refreshNews();
            });
          },
          child: FutureBuilder<List<dynamic>>(
            future: isSearching ? searchNews() : _newsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else {
                List<dynamic> news = snapshot.data!;
                return ListView.builder(
                  itemCount: news.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildCard(news[index]);
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> news) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                news['urlToImage'] ?? 'https://via.placeholder.com/150',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 10),
            Text(
              news['title'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Source: ${news['source']['name']}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Published at: ${news['publishedAt']}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text('News App'),
            accountEmail: null,
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Image(
                fit: BoxFit.cover,
                image: AssetImage(
                    'assets/logo.jpg'), // Replace 'assets/logo.jpg' with your image asset path
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            title: Text('Country'),
            trailing: DropdownButton<String>(
              value: selectedCountry,
              items: countries
                  .map((country) => DropdownMenuItem(
                child: Text(country['name']!),
                value: country['code'],
              ))
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCountry = newValue!;
                  _newsFuture = refreshNews();
                  Navigator.pop(context);
                });
              },
            ),
          ),
          Divider(),
          ListTile(
            title: Text('Category'),
            trailing: DropdownButton<String>(
              value: selectedCategory,
              items: categories
                  .map((category) => DropdownMenuItem(
                child: Text(category['name']!),
                value: category['code'],
              ))
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue!;
                  _newsFuture = refreshNews();
                  Navigator.pop(context);
                });
              },
            ),
          ),
          Divider(),
        ],
      ),
    );
  }

  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  Future<List<dynamic>> searchNews() async {
    // API URL for search
    String apiUrl =
        'https://newsapi.org/v2/top-headlines?q=$searchText&apiKey=$apiKey';

    http.Response response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data['articles'];
    } else {
      print('Failed to load news: ${response.reasonPhrase}');
      throw Exception('Failed to load news');
    }
  }

  Future<List<dynamic>> refreshNews() async {
    String apiUrl;

    if (selectedCategory == "everything") {
      apiUrl =
      'https://newsapi.org/v2/top-headlines?country=$selectedCountry&apiKey=$apiKey';
    } else {
      apiUrl =
      'https://newsapi.org/v2/top-headlines?country=$selectedCountry&category=$selectedCategory&apiKey=$apiKey';
    }

    http.Response response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data['articles'];
    } else {
      // Handle error
      print('Failed to load news: ${response.reasonPhrase}');
      throw Exception('Failed to load news');
    }
  }
}
