SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Incumbencies](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IncumbencyType] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[IncumbentSigner] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ExpiryDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MasterAgreementId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Incumbencies]  WITH CHECK ADD  CONSTRAINT [EMasterAgreement_Incumbencies] FOREIGN KEY([MasterAgreementId])
REFERENCES [dbo].[MasterAgreements] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Incumbencies] CHECK CONSTRAINT [EMasterAgreement_Incumbencies]
GO
