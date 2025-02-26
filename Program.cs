using System;
using System.Data;
using Npgsql;
using Newtonsoft.Json;
using Amazon.SecretsManager;
using Amazon.SecretsManager.Extensions.Caching;

public class SecretsManagerService 
{
    private class dbSecrets
    {
        public required string username { get; set; }
        public required string password { get; set; }
        public required string engine { get; set; }
        public required string host { get; set; }
        public required string port { get; set; }
        public required string dbname { get; set; }
    }

    private SecretsManagerCache cache = new SecretsManagerCache();

    public SecretsManagerService()
    {
        var client = new AmazonSecretsManagerClient();
        cache = new SecretsManagerCache(client);
    }    

    public async Task<(string Host, string Port, string DB, string Username, string Password)> GetCredentialsAsync(string secretName)
    {
        try
            {
                string secretString = await cache.GetSecretString(secretName);
                // Console.WriteLine($"Secret String: {secretString}");
                var secret = JsonConvert.DeserializeObject<dbSecrets>(secretString);

                if (secret == null)
                {
                    throw new InvalidOperationException("Failed to retrieve the secret of DB connection string");
                }

                return (secret.host, secret.port, secret.dbname, secret.username, secret.password);
            }
            catch (Exception ex)
            {
                // Handle exceptions such as secret not found or JSON parsing errors
                Console.WriteLine($"Error retrieving secret: {ex.Message}");
                throw;
            }
    }
}

namespace PostgreSQLDemo
{
    class Program
    {
        static void Main(string[] args)
        {

            var secretName = "sample-apg-conn";
            Console.WriteLine($"Secret Name is: {secretName}");

            var secretsManagerService = new SecretsManagerService();
            var (host, port, dbname, username, password) = secretsManagerService.GetCredentialsAsync(secretName).GetAwaiter().GetResult();

            // Console.WriteLine($"Aurora PostgreSQL Cluster Endpoint: {host}");
            // Console.WriteLine($"Database Name: {dbname}");
            // Console.WriteLine($"Port: {port}");
            // Console.WriteLine($"Username: {username}");
            // Console.WriteLine($"Password: {password}");

            var connString = $"Host={host};Username={username};Password={password};Database={dbname};Port={port}";
            // Console.WriteLine($"Connection String: {connString}");

            string col_list = "$$'y2017', 'y2018', 'y2019', 'y2020', 'y2021', 'y2022'$$";
            string refcursorName = "pivot_cur";

            using var conn = new NpgsqlConnection(connString);
            conn.Open();

            try {
                // Start a transaction as it is required to work with result sets (cursors) in PostgreSQL
                NpgsqlTransaction tx = conn.BeginTransaction();

                // Specify command Stored Procedure 
                var commandText = $"select get_dynamic_pivot_data('{refcursorName}',{col_list})";
                // Console.WriteLine($"Command Text: {commandText}");
                using var cmd = new NpgsqlCommand(commandText, conn);
                cmd.CommandType = CommandType.Text;  

                // Execute the function
                NpgsqlDataReader dr = cmd.ExecuteReader();

                if (dr.Read())
                {
                    // Check if the value is a refcursor
                    if (dr.GetDataTypeName(0) == "refcursor") 
                    {
                        // Get the current refcursor name
                        // var curCursorName = dr.GetValue(0).ToString();
                        // Console.WriteLine($"refcursor Name: {curCursorName}");

                        dr.Close();

                        // Execute the refcursor query
                        using var fetch_cmd = new NpgsqlCommand($"FETCH ALL IN \"{refcursorName}\"", conn);
                        using var refCursorReader = fetch_cmd.ExecuteReader();
      
                        // Load all rows into a DataTable
                        var dataTable = new DataTable();
                        dataTable.Load(refCursorReader);

                        // Print column headers
                        foreach (DataColumn column in dataTable.Columns)
                        {
                            Console.Write(column.ColumnName + "|");
                        }
                        Console.WriteLine();
                        Console.Write("--------------------------------------------------------------");
                        Console.WriteLine();

                        // Print data rows
                        foreach (DataRow row in dataTable.Rows)
                        {
                            int i = 0;
                            foreach (var item in row.ItemArray)
                            {
                                if ( i < 2 ) { 
                                    Console.Write($"{item,-12}" + "|");
                                    i++ ;
                                } else
                                    Console.Write($"{item,-5}" + "|");
                            }
                            Console.WriteLine();
                        }
                    }
                }

                tx.Commit();
            } 
            catch (NpgsqlException ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
            }

            conn.Close();

        }

    }
}
