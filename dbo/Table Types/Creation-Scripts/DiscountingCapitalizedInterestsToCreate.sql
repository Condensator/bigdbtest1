CREATE TYPE [dbo].[DiscountingCapitalizedInterestsToCreate] AS TABLE(
	[CapitalizationDate] [date] NOT NULL,
	[CapitalizedAmount] [decimal](16, 2) NOT NULL,
	[Source] [nvarchar](36) COLLATE Latin1_General_CI_AS NOT NULL
)
GO
